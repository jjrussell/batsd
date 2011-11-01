class SimpledbResource

  include Simpledb

  cattr_reader :sdb
  attr_accessor :key, :attributes, :this_domain_name, :is_new, :key_hash
  cattr_accessor :domain_name, :key_format
  superclass_delegating_accessor :domain_name, :key_format
  class_inheritable_accessor :attribute_names

  def self.reset_connection
    @@sdb = RightAws::SdbInterface.new(nil, nil, { :multi_thread => true, :port => 80, :protocol => 'http' })
  end
  self.reset_connection

  @@special_values = {
    :newline => "^^TAPJOY_NEWLINE^^",
    :escaped => "^^TAPJOY_ESCAPED^^"
  }

  self.attribute_names = [ 'id', 'key' ]

  ##
  # Initializes a new SimpledbResource, which represents a single row in a domain.
  # options:
  #   domain_name: The name of the domain
  #   key: The item key
  #   attributes: The attributes for this item. If load is true, this will be overwritten.
  #   load: Whether the item attributes should be loaded at all.
  #   load_from_memcache: Whether attributes should be loaded from memcache.
  def initialize(options = {})
    should_load                = options.delete(:load)                 { true }
    load_from_memcache         = options.delete(:load_from_memcache)   { true }
    consistent                 = options.delete(:consistent)           { false }
    run_after_initialize       = options.delete(:after_initialize)     { true }
    @key                       = get_key_from(options.delete(:key))    { nil }
    @this_domain_name          = options.delete(:domain_name)          { dynamic_domain_name() }
    @attributes                = options.delete(:attributes)           { {} }
    @attributes_to_add         = options.delete(:attrs_to_add)         { {} }
    @attributes_to_replace     = options.delete(:attrs_to_replace)     { {} }
    @attributes_to_delete      = options.delete(:attrs_to_delete)      { {} }
    @attribute_names_to_delete = options.delete(:attr_names_to_delete) { [] }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    @this_domain_name = get_real_domain_name(@this_domain_name)
    setup_key_hash

    load(load_from_memcache, consistent) if should_load
    @is_new = @attributes.empty?

    after_initialize if run_after_initialize
  end

  def after_initialize
  end

  def self.sdb_attr(name, options = {})
    type          = options.delete(:type)          { :string }
    default_value = options.delete(:default_value)
    cgi_escape    = options.delete(:cgi_escape)    { false }
    force_array   = options.delete(:force_array)   { false }
    replace       = options.delete(:replace)       { true }
    attr_name     = options.delete(:attr_name)     { name.to_s }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    get_options = {
      :type => type,
      :force_array => force_array,
      :default_value => default_value
    }

    put_options = {
      :type => type,
      :cgi_escape => cgi_escape,
      :replace => replace
    }

    module_eval %Q{
      def #{name.to_s}()
        get('#{attr_name}', #{get_options.inspect})
      end
    }

    module_eval %Q{
      def #{name.to_s}=(value)
        put('#{attr_name}', value, #{put_options.inspect})
      end
    }

    module_eval %Q{
      def #{name.to_s}?
        !get('#{attr_name}', #{get_options.inspect}).blank?
      end
    }

    self.attribute_names << attr_name.to_s
  end
  self.sdb_attr :updated_at, {:type => :time, :attr_name => 'updated-at'}

  def id
    @key
  end

  def id=(key)
    @key = key
  end

  def new_record?
    @is_new
  end

  ##
  # Attempt to load the item attributes from memcache. If they are not found,
  # they will attempt be loaded from simpledb. If thet are still not found,
  # an empty attributes hash will be created.
  def load(load_from_memcache = true, consistent = false)
    if load_from_memcache
      @attributes = Mc.get(get_memcache_key) do
        attrs = load_from_sdb(consistent)
        unless attrs.empty?
          Mc.put(get_memcache_key, attrs) rescue nil
        end
        attrs
      end
    else
      @attributes = load_from_sdb(consistent)
    end
  end

  ##
  # Calls serial_save in a separate thread.
  def save(options = {})
    thread = Thread.new(options) do |opts|
      serial_save(opts)
    end
    return thread
  end

  def save!(options = {})
    serial_save({ :catch_exceptions => false }.merge(options))
  end

  ##
  # Updates the 'updated-at' attribute of this item, and saves it to SimpleDB.
  # If the domain does not exist, then the domain is created.
  # options:
  #   write_to_memcache: Whether to write these attributes to memcache.
  #   updated_at: Whether to include an updated-at attribute.
  #   write_to_sdb: Whether to save to sdb. This may be set to false if saves are occuring in a batch put.
  #   catch_exceptions: Whether to catch exceptions. If true, then any failed attempts to save will
  #       result in the save getting written to sqs in order to be saved later.
  def serial_save(options = {})
    options_copy     = options.clone
    save_to_memcache = options.delete(:write_to_memcache) { true }
    save_to_sdb      = options.delete(:write_to_sdb)      { true }
    catch_exceptions = options.delete(:catch_exceptions)  { true }
    expected_attr    = options.delete(:expected_attr)     { {} }
    from_queue       = options.delete(:from_queue)        { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    Rails.logger.info "Saving to #{@this_domain_name}"

    now = Time.zone.now

    if from_queue
      put('from_queue', now.to_f.to_s)
    else
      put('updated-at', now.to_f.to_s)
    end

    Rails.logger.info_with_time("Saving to sdb, domain: #{this_domain_name}") do
      self.write_to_memcache if save_to_memcache
      self.write_to_sdb(expected_attr) if save_to_sdb
      @is_new = false
      @attributes_to_add.clear
      @attributes_to_replace.clear
      @attributes_to_delete.clear
      @attribute_names_to_delete.clear
    end
  rescue ExpectedAttributeError => e
    if save_to_memcache
      Mc.delete(get_memcache_key) rescue nil
    end
    raise e
  rescue Exception => e
    if e.is_a?(RightAws::AwsError)
      Mc.increment_count("failed_sdb_saves.sdb.#{@this_domain_name}.#{(now.to_f / 1.hour).to_i}", false, 1.day)
    else
      Mc.increment_count("failed_sdb_saves.mc.#{@this_domain_name}.#{(now.to_f / 1.hour).to_i}", false, 1.day)
    end
    unless catch_exceptions
      if save_to_memcache && !from_queue
        Mc.delete(get_memcache_key) rescue nil
      end
      raise e
    end
    return if @this_domain_name =~ /^#{RUN_MODE_PREFIX}devices_/
    Rails.logger.info "Sdb save failed. Adding to sqs. Domain: #{@this_domain_name} Key: #{@key} Exception: #{e.class} - #{e}"
    uuid = UUIDTools::UUID.random_create.to_s
    bucket = S3.bucket(BucketNames::FAILED_SDB_SAVES)
    bucket.objects["incomplete/#{uuid}"].write(:data => self.serialize)
    message = { :uuid => uuid, :options => options_copy }.to_json
    Sqs.send_message(QueueNames::FAILED_SDB_SAVES, message)
    Rails.logger.info "Successfully added to sqs. Message: #{message}"
  ensure
    Rails.logger.flush
  end

  ##
  # Gets value(s) for a given attribute name.
  # If the attr_name is associated with only one value, then that value is returned.
  # If it is associated with multiple values, then all values are returned in an array.
  # options:
  #   force_array: Forces the return value to be an array, even if the attr_name is only associated
  #       with one value. Returns an empty array of no values are associated with attr_name.
  #   default_value: The value to return if no values are associated with attr_name. Not used
  #       if force_array is set to true (an empty array will be returned instead).
  #   type: The type of value that is being stored. The value will be converted to the type before
  #       being returned. Acceptable values are listed in TypeConverters::TYPES.
  def get(attr_name, options = {})
    force_array   = options.delete(:force_array)   { false }
    default_value = options.delete(:default_value)
    type          = options.delete(:type)          { :string }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Unknown type conversion: #{type}" unless TypeConverters::TYPES.include?(type)

    attr_array = @attributes[attr_name]

    unless @attributes[attr_name]
      return force_array ? [] : default_value
    end

    if not force_array and @attributes[attr_name].first.length >= 1000
      joined_value = ''
      while @attributes[attr_name] && @attributes[attr_name].first.length >= 1000 do
        joined_value += @attributes[attr_name].first
        attr_name += '_'
      end

      joined_value += @attributes[attr_name].first if @attributes[attr_name]

      attr_array = [joined_value]
    end

    attr_array = attr_array.map do |value|
      TypeConverters::TYPES[type].from_string(unescape_specials(value))
    end

    return attr_array.first if not force_array and attr_array.length == 1
    return attr_array
  end

  ##
  # Puts a value to be associated with an attribute name.
  def put(attr_name, value, options = {})
    replace    = options.delete(:replace)    { true }
    cgi_escape = options.delete(:cgi_escape) { false }
    type       = options.delete(:type)       { :string }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Unknown type conversion: #{type}" unless TypeConverters::TYPES.include?(type)

    if value.nil?
      return
    end
    value = TypeConverters::TYPES[type].to_string(value)

    value = escape_specials(value, {:cgi_escape => cgi_escape})

    value_array = value.scan(/.{1,1000}/)
    value_array.each do |part|
      raw_put(attr_name, part, replace)
      attr_name += '_'
    end
    delete_extra_attributes(attr_name)
  end

  ##
  # Adds a value to be deleted. Also removes it from the hash of attributes.
  def delete(attr_name, value = nil)
    if value
      @attributes_to_delete[attr_name] = Array(value) | Array(@attributes_to_delete[attr_name])
    else
      @attribute_names_to_delete.push(attr_name)
      @attributes.delete(attr_name)
    end

    if @attributes[attr_name]
      @attributes[attr_name].delete(value)
      @attributes.delete(attr_name) if @attributes[attr_name].empty?
    end
  end

  ##
  # Deletes this entire row immediately (no need to call save after calling this).
  def delete_all(delete_from_memcache = true)
    Mc.delete(get_memcache_key) if delete_from_memcache
    @@sdb.delete_attributes(@this_domain_name, key)
  end

  def changed?
    !(@attributes_to_add.empty? && @attributes_to_replace.empty? && @attributes_to_delete.empty? && @attribute_names_to_delete.empty?)
  end

  ##
  # Loads a single row from this domain, modifies it, and saves it. Uses SDB's Conditional Put
  # on the 'version' attribute to ensure that the row has been unmodified during the course of
  # the transaction. If the row has been modified, then the transaction will be retried, up to
  # the amount of times s
  def self.transaction(load_options, options = {})
    version_attr = options.delete(:version_attr) { 'version' }
    retries      = options.delete(:retries)      { 3 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    load_options = {:consistent => true, :load_from_memcache => false}.merge(load_options)

    begin
      row = self.new(load_options.dup)
      initial_version = row.get(version_attr)

      yield(row)

      row.put(version_attr, initial_version.to_i + 1)
      row.serial_save(:catch_exceptions => false, :expected_attr => {version_attr => initial_version}, :write_to_memcache => false)
      return row
    rescue ExpectedAttributeError => e
      Rails.logger.info "ExpectedAttributeError: #{e.to_s}."
      if retries > 0
        retries -= 1
        sleep(0.1)
        retry
      else
        raise e
      end
    end
  end

  ##
  # Performs a batch_put_attributes.
  def self.put_items(items, options = {})
    replace = options.delete(:replace) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    raise "Too many items to batch_put" if items.length > 25
    return {} if items.length == 0

    batch_put_domain_name = items[0].this_domain_name
    items_object = {}
    items.each do |item|
      raise "All domain names must be the same for batch_put_attributes. #{item.this_domain_name} != #{batch_put_domain_name}" if item.this_domain_name != batch_put_domain_name
      items_object[item.key] = item.attributes
    end
    return @@sdb.batch_put_attributes(batch_put_domain_name, items_object, replace)
  end

  ##
  # Runs a select count(*) for the specified domain, with the specified where clause,
  # and returns the number.
  def self.count(options = {})
    where       = options.delete(:where)
    next_token  = options.delete(:next_token)
    domain_name = options.delete(:domain_name) { self.domain_name }
    retries     = options.delete(:retries)     { 10 }
    consistent  = options.delete(:consistent)  { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Must provide a domain name" unless domain_name

    domain_name = get_real_domain_name(domain_name)

    query = "SELECT count(*) FROM `#{domain_name}`"
    query += " WHERE #{where}" if where

    count = 0
    loop do
      begin
        response = @@sdb.select(query, next_token, consistent)
      rescue RightAws::AwsError => e
        if e.message =~ /^(ServiceUnavailable|QueryTimeout)/ && retries > 0
          Rails.logger.info "Error: #{e}. Retrying up to #{retries} more times."
          retries -= 1
          retry
        else
          raise e
        end
      end

      count += response[:items][0]['Domain']['Count'][0].to_i

      next_token = response[:next_token]
      break if next_token.nil?
    end
    return count
  end

  def self.count_async(options = {})
    where       = options.delete(:where)
    next_token  = options.delete(:next_token)
    domain_name = options.delete(:domain_name) { self.domain_name }
    limit       = options.delete(:limit)
    consistent  = options.delete(:consistent)  { false }
    hydra       = options.delete(:hydra)       { Typhoeus::Hydra.new }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Must provide a domain name" unless domain_name

    hydra.disable_memoization

    domain_name = get_real_domain_name(domain_name)

    query = "SELECT count(*) FROM `#{domain_name}`"
    query += " WHERE #{where}" if where
    query += " LIMIT #{limit}" if limit

    self.send_count_async_request(query, next_token, consistent, hydra) do |count|
      yield count
    end

    return hydra
  end

  def self.send_count_async_request(query, next_token, consistent, hydra)
    retries = 20
    sdb_request = @@sdb.generate_request('Select', { 'SelectExpression' => query, 'NextToken' => next_token, 'ConsistentRead' => consistent })
    url = "#{sdb_request[:protocol]}://#{sdb_request[:server]}:#{sdb_request[:port]}#{sdb_request[:request].path}"
    request = Typhoeus::Request.new(url)
    request.on_complete do |response|
      if response.code != 200
        retries -= 1
        if retries > 0
          hydra.queue(request)
          Rails.logger.info "Async count encountered an error and is being re-queued. Code: #{response.code}, Response: #{response.body}"
        else
          raise RightAws::AwsError.new("Async count encountered an error. Code: #{response.code}, Response: #{response.body}")
        end
      else
        parser = RightAws::SdbInterface::QSdbSelectParser.new
        parser.parse(response.body)
        count = parser.result[:items][0]['Domain']['Count'][0].to_i
        next_token = parser.result[:next_token]
        if next_token.present?
          self.send_count_async_request(query, next_token, consistent, hydra) do |c|
            yield count + c
          end
        else
          yield count
        end
      end
    end
    hydra.queue(request)
  end

  ##
  # Returns an array of items which match the specified select parameters.
  def self.select(options = {})
    attrs       = options.delete(:attributes)  { '*' }
    order_by    = options.delete(:order_by)
    where       = options.delete(:where)
    limit       = options.delete(:limit)
    next_token  = options.delete(:next_token)
    domain_name = options.delete(:domain_name) { self.domain_name }
    retries     = options.delete(:retries)     { 10 }
    consistent  = options.delete(:consistent)  { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Must provide a domain name" unless domain_name

    domain_name = get_real_domain_name(domain_name)

    query = "SELECT #{attrs} FROM `#{domain_name}`"
    query += " WHERE #{where}" if where
    query += " ORDER BY #{order_by}" if order_by
    query += " LIMIT #{limit}" if limit

    sdb_item_array = []
    box_usage = 0
    retry_count = 0

    loop do
      begin
        response = @@sdb.select(query, next_token, consistent)
      rescue RightAws::AwsError => e
        if e.message =~ /^(ServiceUnavailable|QueryTimeout)/ && retry_count < retries
          Rails.logger.info "Error: #{e}. Retrying up to #{retries - retry_count} more times."
          retry_count += 1
          retry
        else
          Rails.logger.error "Error in query: #{query}"
          raise e
        end
      end

      response[:items].each do |item|

        sdb_item = self.new({
          :key => item.keys[0],
          :load => false,
          :domain_name => domain_name,
          :attributes => item.values[0]})
        sdb_item.attributes = item.values[0]
        if block_given?
          yield(sdb_item)
        else
          sdb_item_array.push(sdb_item)
        end
      end
      box_usage += response[:box_usage].to_f

      unless block_given?
        return {
          :items => sdb_item_array,
          :next_token => response[:next_token],
          :box_usage => box_usage,
          :retry_count => retry_count
        }
      end

      next_token = response[:next_token]
      break if next_token.nil?
    end

    return {:box_usage => box_usage}
  rescue => e
    Rails.logger.error("Error while processing query: #{query}")
    raise e
  end

  def self.create_domain(domain_name)
    domain_name = get_real_domain_name(domain_name)
    return @@sdb.create_domain(domain_name)
  end

  def self.delete_domain(domain_name)
    domain_name = get_real_domain_name(domain_name)
    return @@sdb.delete_domain(domain_name)
  end

  def self.get_domain_names
    domain_names = Set.new
    @@sdb.list_domains do |result|
      result[:domains].each do |domain_name|
        domain_names << domain_name
      end
    end
    domain_names
  end

  ##
  # Stores the domain name, item key and attributes to a json string.
  # options:
  #  attributes_only: Only serialize the current state, not attrs_to_add, attrs_to_replace, etc.
  def serialize(options = {})
    attributes_only = options.delete(:attributes_only) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    obj = {:domain => @this_domain_name, :key => @key, :attrs => @attributes}
    unless attributes_only
      obj[:attrs_to_add] = @attributes_to_add unless @attributes_to_add.empty?
      obj[:attrs_to_replace] = @attributes_to_replace unless @attributes_to_replace.empty?
      obj[:attrs_to_delete] = @attributes_to_delete unless @attributes_to_delete.empty?
      obj[:attr_names_to_delete] = @attribute_names_to_delete unless @attribute_names_to_delete.empty?
    end

    return obj.to_json
  end

  ##
  # Re-creates this item from a json string.
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    attributes = json['attrs']
    domain_name = json['domain']
    attrs_to_add = json['attrs_to_add']
    attrs_to_replace = json['attrs_to_replace']
    attrs_to_delete = json['attrs_to_delete']
    attr_names_to_delete = json['attr_names_to_delete']

    options = {:load => false, :domain_name => domain_name, :key => key, :attributes => attributes}
    options[:attrs_to_add] = attrs_to_add if attrs_to_add
    options[:attrs_to_replace] = attrs_to_replace if attrs_to_replace
    options[:attrs_to_delete] = attrs_to_delete if attrs_to_delete
    options[:attr_names_to_delete] = attr_names_to_delete if attr_names_to_delete

    return self.new(options)
  end

  ##
  # Generates ActiveRecord-like find_by_#{attribute_name}(attribute_value) methods when appropriate.
  # Both "id" and "key" can be used to look up SimpleDB itemname() values.
  # examples:
  # ActivityLog.find_all_by_user_and_controller('ryan', 'statz')
  # finds all ActivityLog records with user='ryan' and controller='statz'
  #
  # ActivityLog.find_by_object_type_and_id('Currency', 'b6bc028f-fa71-4a4d-8311-8005474e9353')
  # finds the first ActivityLog record with object_type='Currency' and id = 'b6bc028f-fa71-4a4d-8311-8005474e9353'
  #
  def self.method_missing(method_id, *arguments, &block)
    if match = DynamicFinderMatch.match(method_id)
      matched_attribute_names = match.attribute_names
      super unless matched_attribute_names.all? { |name| attribute_names.include?(name) }

      self.class_eval %{
        def self.#{method_id}(*args)
          options = args.extract_options!
          where_attributes = {}
          [:#{matched_attribute_names.join(',:')}].each_with_index { |name, idx| where_attributes[name] = args[idx] }

          where_attributes["itemname()"] = where_attributes[:key] if where_attributes[:key]
          where_attributes["itemname()"] = where_attributes[:id] if where_attributes[:id]
          where_attributes.delete(:key)
          where_attributes.delete(:id)

          options[:where] = where_attributes.collect { |key, value| key.to_s + " = " + "'" + value.to_s + "'" }.join(" and ")
          find(:#{match.finder}, options)
        end
      }, __FILE__, __LINE__

      send(method_id, *arguments)
    else
      super
    end
  end

  def ==(other)
    other.is_a?(SimpledbResource) && (self.attributes == other.attributes) && (self.id == other.id) && (self.domain_name == other.domain_name)
  end

protected

  def write_to_sdb(expected_attr = {})
    sdb_interface = RightAws::SdbInterface.new(nil, nil, {:multi_thread => true, :port => 80, :protocol => 'http'})
    attributes_to_put = @attributes_to_add.merge(@attributes_to_replace)
    attributes_to_delete = @attributes_to_delete.clone
    @attribute_names_to_delete.each do |attr_name_to_delete|
      attributes_to_delete[attr_name_to_delete] = :all
    end

    begin
      unless attributes_to_put.empty?
        sdb_interface.put_attributes(@this_domain_name, @key, attributes_to_put, @attributes_to_replace.keys, expected_attr)
      end
      unless attributes_to_delete.empty?
        sdb_interface.delete_attributes(@this_domain_name, @key, attributes_to_delete, expected_attr)
      end
    rescue RightAws::AwsError => e
      if e.message.starts_with?("NoSuchDomain") && !Rails.env.production?
        Rails.logger.info_with_time("Creating new domain: #{@this_domain_name}") do
          sdb_interface.create_domain(@this_domain_name)
        end
        retry
      elsif e.message.starts_with?("ConditionalCheckFailed") || e.message.starts_with?("AttributeDoesNotExist")
        raise ExpectedAttributeError.new(e.message)
      else
        raise e
      end
    end
  end

  def write_to_memcache
    Mc.compare_and_swap(get_memcache_key) do |mc_attributes|
      if mc_attributes
        mc_attributes.merge!(@attributes_to_replace)
        @attributes_to_add.each do |key, values|
          mc_attributes[key] = Array(mc_attributes[key]) | values
        end

        @attributes_to_delete.each do |key, values|
          if mc_attributes[key]
            values.each do |value|
              mc_attributes[key].delete(value)
            end
            mc_attributes.delete(key) if mc_attributes[key].empty?
          end
        end

        @attribute_names_to_delete.each do |attr_name|
          mc_attributes.delete(attr_name)
        end

        @attributes = mc_attributes
      end

      @attributes
    end
  end

private

  def load_from_sdb(consistent = false)
    attributes = {}
    begin
      response = @@sdb.get_attributes(@this_domain_name, @key, nil, consistent)
      attributes = response[:attributes]
    rescue RightAws::AwsError => e
      if e.message.starts_with?("NoSuchDomain")
        Rails.logger.info "NoSuchDomain: #{@this_domain_name}, when attempting to load #{@key}"
        # Domain will be created on save.
      elsif e.message =~ /getaddrinfo/
        # Attempt to reload?
        raise e
      else
        raise e
      end
    end
    return attributes
  end

  def get_key_from(key_obj)
    if key_obj.nil?
      return UUIDTools::UUID.random_create.to_s
    elsif key_obj.class == Hash
      # TODO: use the @@key_format variable to parse the key
      raise "hash key_obj not implemented yet"
    else
      return key_obj.to_s
    end
  end

  def setup_key_hash
    key_hash = nil
    unless key_format.nil?
      key_hash = {}

      key_parts = @key.split('.')
      key_format_parts = key_format.split('.')

      key_format_parts.each_index do |i|
        key_hash[key_format_parts[i].to_sym] = key_parts[i]
      end
    end
  end

  def get_memcache_key
    "sdb.#{@this_domain_name}.#{@key}"
  end

  # Return the domain name, but strip any pre-existing run mode prefix, in order to ensure that
  # only one prefix is added.
  def self.get_real_domain_name(domain_name)
    RUN_MODE_PREFIX + domain_name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
  end

  def get_real_domain_name(domain_name)
    SimpledbResource.get_real_domain_name(domain_name)
  end

  def dynamic_domain_name
    return self.domain_name
  end

  def unescape_specials(value)
    value = value.gsub(@@special_values[:newline], "\n")

    if value.starts_with?(@@special_values[:escaped])
      value = value.gsub(@@special_values[:escaped], '')
      value = CGI::unescape(value)
    end

    return value
  end

  def escape_specials(value, options = {})
    cgi_escape = options.delete(:cgi_escape) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    return value if value.blank?

    if cgi_escape
      value = @@special_values[:escaped] + CGI::escape(value)
    else
      value = value.gsub("\r\n", @@special_values[:newline])
      value = value.gsub("\n", @@special_values[:newline])
      value = value.gsub("\r", @@special_values[:newline])
    end

    return value
  end

  ##
  # Puts a value directly in to the attributes array, as well as the attributes_to_replace or
  # attributes_to_add arrays.
  def raw_put(attr_name, value, replace)
    if replace
      @attributes[attr_name] = Array(value)
      @attributes_to_replace[attr_name] = Array(value)
    else
      @attributes[attr_name] = Array(value) | Array(@attributes[attr_name])
      @attributes_to_add[attr_name] = Array(value) | Array(@attributes_to_add[attr_name])
    end
  end

  ##
  # Delete any extra attributes that exist with an extra '_' after them, starting with the attr_name
  # passed in. This will be called because the value may have gotten shorter.
  def delete_extra_attributes(attr_name)
    while @attributes[attr_name] do
      delete(attr_name)
      attr_name += '_'
    end
  end

end
