require 'sdb_batchput'

class StringConverter
  def from_string(s)
    s
  end
  def to_string(s)
    s.to_s
  end
end

class IntConverter
  def from_string(s)
    s.to_i
  end
  def to_string(i)
    i.to_s
  end
end

class FloatConverter
  def from_string(s)
    s.to_f
  end
  def to_string(f)
    f.to_s
  end
end

class TimeConverter
  def from_string(s)
    Time.at(s.to_f).utc
  end
  def to_string(t)
    t.to_f.to_s
  end
end

class SimpledbResource  
  include TimeLogHelper
  include MemcachedHelper
  include RightAws
  include SqsHelper
  
  attr_accessor :key, :attributes, :this_domain_name, :is_new
  cattr_accessor :domain_name, :key_format
  superclass_delegating_accessor :domain_name, :key_format
  
  def self.reset_connection
    #sdb_ip_address = Socket::getaddrinfo('sdb.amazonaws.com', 'http')[0][3]
    #Rails.logger.info "Resetting sdb connection. Sdb ip address: #{sdb_ip_address}"
    @@sdb = SdbInterface.new(nil, nil,
        {:multi_thread => true, :port => 80, :protocol => 'http'})
  end
  self.reset_connection
  
  @@type_converters = {
    :string => StringConverter.new,
    :int => IntConverter.new,
    :float => FloatConverter.new,
    :time => TimeConverter.new
  }
  
  ##
  # Initializes a new SimpledbResource, which represents a single row in a domain.
  # options:
  #   domain_name: The name of the domain
  #   key: The item key
  #   attributes: The attributes for this item. If load is true, this will be overwritten.
  #   load: Whether the item attributes should be loaded at all.
  #   load_from_memcache: Whether attributes should be loaded from memcache.
  def initialize(options = {})
    should_load =                options.delete(:load)                 { true }
    load_from_memcache =         options.delete(:load_from_memcache)   { true }
    @key =                       get_key_from(options.delete(:key))
    @this_domain_name =          options.delete(:domain_name)          { dynamic_domain_name() }
    @attributes =                options.delete(:attributes)           { {} }
    @attributes_to_add =         options.delete(:attrs_to_add)         { {} }
    @attributes_to_replace =     options.delete(:attrs_to_replace)     { {} }
    @attributes_to_delete =      options.delete(:attrs_to_delete)      { {} }
    @attribute_names_to_delete = options.delete(:attr_names_to_delete) { [] }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    @this_domain_name = get_real_domain_name(@this_domain_name)
    
    @special_values = {
      :newline => "^^TAPJOY_NEWLINE^^",
      :escaped => "^^TAPJOY_ESCAPED^^"
    }
    
    load(load_from_memcache) if should_load
    @is_new = @attributes.empty?
  end
  
  def self.sdb_attr(name, type = :string, default_value = nil)
    module_eval %Q{
      def #{name.to_s}()
        get('#{name.to_s}', :type => #{type.inspect}, :default_value => #{default_value.inspect}) 
      end
    }
    
    module_eval %Q{
      def #{name.to_s}=(value)
        put('#{name.to_s}', value, :type => :#{type})
      end
    }
  end
  
  ##
  # Attempt to load the item attributes from memcache. If they are not found,
  # they will attempt be loaded from simpledb. If thet are still not found,
  # an empty attributes hash will be created.
  def load(load_from_memcache = true)
    if load_from_memcache
      @attributes = get_from_cache(get_memcache_key) do
        attrs = load_from_sdb
        unless attrs.empty?
          save_to_cache(get_memcache_key, attrs)
        end
        attrs
      end
    else
      @attributes = load_from_sdb
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
    options_copy = options.clone
    write_to_memcache = options.delete(:write_to_memcache) { true }
    updated_at = options.delete(:updated_at) { true }
    write_to_sdb = options.delete(:write_to_sdb) { true }
    catch_exceptions = options.delete(:catch_exceptions) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    Rails.logger.info "Saving to #{@this_domain_name}"

    put('updated-at', Time.now.utc.to_f.to_s) if updated_at
    
    time_log("Saving to sdb") do
      if write_to_sdb
        begin
          @@sdb.put_attributes(@this_domain_name, @key, @attributes_to_replace, true) unless @attributes_to_replace.empty?
          @@sdb.put_attributes(@this_domain_name, @key, @attributes_to_add, false) unless @attributes_to_add.empty?
          @@sdb.delete_attributes(@this_domain_name, @key, @attributes_to_delete) unless @attributes_to_delete.empty?
          @@sdb.delete_attributes(@this_domain_name, @key, @attribute_names_to_delete) unless @attribute_names_to_delete.empty?
        rescue AwsError => e
          if e.message.starts_with?("NoSuchDomain")
            time_log("Creating new domain: #{@this_domain_name}") do
              @@sdb.create_domain(@this_domain_name)
            end
            retry
          else
            raise e
          end
        end
      end
      
      if write_to_memcache
        compare_and_swap_in_cache(get_memcache_key) do |mc_attributes|
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
    end
  rescue Exception => e
    unless catch_exceptions
      raise e
    end
    
    Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"
    s3 = RightAws::S3.new(nil, nil, :multi_thread => true)
    uuid = UUIDTools::UUID.random_create.to_s
    bucket = s3.bucket('failed-sdb-saves')
    bucket.put(uuid, self.serialize)
    message = {:uuid => uuid, :options => options_copy}.to_json
    send_to_sqs(QueueNames::FAILED_SDB_SAVES, message)
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
  #       if force_array is set to true.
  #   type: The type of value that is being stored. The value will be converted to the type before
  #       being returned. Acceptable values are listed in @@type_converters.
  def get(attr_name, options = {})
    force_array = options.delete(:force_array) { false }
    default_value = options.delete(:default_value)
    type = options.delete(:type) { :string }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Unknown type conversion: #{type}" unless @@type_converters.include?(type)
    
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
      @@type_converters[type].from_string(unescape_specials(value))
    end
    
    return attr_array.first if not force_array and attr_array.length == 1
    return attr_array
  end
  
  ##
  # Puts a value to be associated with an attribute name.
  def put(attr_name, value, options = {})
    replace = options.delete(:replace) { true }
    cgi_escape = options.delete(:cgi_escape) { false }
    type = options.delete(:type) { :string }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Unknown type conversion: #{type}" unless @@type_converters.include?(type)
    
    if value.nil? or value == ''
      return
    end
    value = @@type_converters[type].to_string(value)
    
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
    end
    
    if @attributes[attr_name]
      @attributes[attr_name].delete(value)
      @attributes.delete(attr_name) if @attributes[attr_name].empty?
    end
  end
  
  ##
  # Deletes this entire row immediately (no need to call save after calling this).
  def delete_all
    delete_from_cache(get_memcache_key)
    @@sdb.delete_attributes(@this_domain_name, key)
  end
  
  ##
  # Performs a batch_put_attributes.
  def self.put_items(items, options = {})
    replace = options.delete(:replace) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    raise "Too many items to batch_put" if items.length >25
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
    where =       options.delete(:where)
    domain_name = options.delete(:domain_name) { self.domain_name }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Must provide a domain name" unless domain_name

    domain_name = get_real_domain_name(domain_name)

    query = "SELECT count(*) FROM `#{domain_name}`"
    query += " WHERE #{where}" if where
    
    count = 0
    response = @@sdb.select(query) do |response|
      count += response[:items][0]['Domain']['Count'][0].to_i
    end
    return count
  end
  
  ##
  # Returns an array of items which match the specified select parameters.
  def self.select(options = {})
    attrs =       options.delete(:attributes) { '*' }
    order_by =    options.delete(:order_by)
    where =       options.delete(:where)
    limit =       options.delete(:limit)
    next_token =  options.delete(:next_token)
    domain_name = options.delete(:domain_name) { self.domain_name }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    raise "Must provide a domain name" unless domain_name
    
    domain_name = get_real_domain_name(domain_name)
    
    query = "SELECT #{attrs} FROM `#{domain_name}`"
    query += " WHERE #{where}" if where
    query += " ORDER BY #{order_by}" if order_by
    query += " LIMIT #{limit}" if limit
    
    sdb_item_array = []
    box_usage = 0
    
    @@sdb.select(query, next_token) do |response|
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
          :box_usage => box_usage
        }
      end
      
      block_given?
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
  
  private
  
  def load_from_sdb
    attributes = {}
    begin
      response = @@sdb.get_attributes(@this_domain_name, @key)
      attributes = response[:attributes]
    rescue AwsError => e
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
    value = value.gsub(@special_values[:newline], "\n")
    
    if value.starts_with?(@special_values[:escaped])
      value = value.gsub(@special_values[:escaped], '')
      value = CGI::unescape(value)
    end
    
    return value
  end
  
  def escape_specials(value, options = {})
    cgi_escape = options.delete(:cgi_escape) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    if cgi_escape
      value = @special_values[:escaped] + CGI::escape(value)
    else
      value = value.gsub("\r\n", @special_values[:newline])
      value = value.gsub("\n", @special_values[:newline])
      value = value.gsub("\r", @special_values[:newline])
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