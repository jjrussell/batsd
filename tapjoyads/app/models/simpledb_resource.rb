require 'sdb_batchput'

class SimpledbResource  
  include TimeLogHelper
  include MemcachedHelper
  include RightAws
  
  attr_accessor :domain_name, :key, :attributes
  
  def self.reset_connection
    @@sdb = SdbInterface.new(nil, nil,
        {:multi_thread => true, :port => 80, :protocol => 'http'})
  end
  self.reset_connection
  
  ##
  # Initializes a new SimpledbResource, which represents a single row in a domain.
  # domain_name: The name of the domain
  # key: The item key
  # options:
  #   load: Whether the item attributes should be loaded at all.
  #   load_from_memcache: Whether attributes should be loaded from memcache.
  def initialize(domain_name, key, options = {})
    should_load = options.delete(:load) { true }
    load_from_memcache = options.delete(:load_from_memcache) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    @domain_name = get_real_domain_name(domain_name)
    @key = key
    @attributes = {}
    @attributes_to_add = {}
    @attributes_to_replace = {}
    @attributes_to_delete = {}
    
    @special_values = {
      :newline => "^^TAPJOY_NEWLINE^^",
      :escaped => "^^TAPJOY_ESCAPED^^"
    }
    
    if should_load
      load(load_from_memcache)
    end
  end
  
  ##
  # Attempt to load the item attributes from memcache. If they are not found,
  # they will attempt be loaded from simpledb. If thet are still not found,
  # an empty attributes hash will be created.
  def load(load_from_memcache = true)
    if load_from_memcache
      @attributes = get_from_cache_and_save(get_memcache_key) do
        load_from_sdb
      end
    else
      @attributes = load_from_sdb
    end
  end
  
  ##
  # Calls serial_save in a separate thread.
  def save(options = {})
    thread = nil
    time_log("Spawing save thread") do
      thread = Thread.new(options) do |opts|
        serial_save(opts)
      end
    end
    return thread
  end
  
  ##
  # Updates the 'updated-at' attribute of this item, and saves it to SimpleDB.
  # If the domain does not exist, then the domain is created.
  # options:
  #   write_to_memcache: Whether to write these attributes to memcache.
  #   replace: Whether to replace attribute values with identical names. It is important to note that
  #     if load() has not been called, and replace is set to true, it is possible to overwrite
  #     attribute values.
  #   updated_at: Whether to include an updated-at attribute.
  def serial_save(options = {})
    write_to_memcache = options.delete(:write_to_memcache) { true }
    replace = options.delete(:replace) { true }
    updated_at = options.delete(:updated_at) { true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    Rails.logger.info "Saving to #{@domain_name}"
    
    time_log("Saving to sdb") do
      put('updated-at', Time.now.utc.to_f.to_s) if updated_at
      
      begin
        @@sdb.put_attributes(@domain_name, @key, @attributes, replace)
        @@sdb.delete_attributes(@domain_name, @key, @attributes_to_delete) unless @attributes_to_delete.empty?
      rescue AwsError => e
        if e.message.starts_with?("NoSuchDomain")
          time_log("Creating new domain: #{@domain_name}") do
            @@sdb.create_domain(@domain_name)
          end
          retry
        else
          raise e
        end
      end
    end
  
    if write_to_memcache
      cache = CACHE.clone
      begin
        cache.cas(get_memcache_key) do |mc_attributes|
          mc_attributes.merge!(@attributes_to_replace)
          @attributes_to_add.each do |key, values|
            mc_attributes[key] = Array(mc_attributes[key]) | values
          end
        
          @attributes_to_delete.each do |key, values|
            if values.empty?
              mc_attributes.delete(key)
            elsif mc_attributes[key]
              values.each do |value|
                mc_attributes[key].delete(value)
              end
              mc_attributes.delete(key) if mc_attributes[key].empty?
            end
          end
          @attributes = mc_attributes

          @attributes
        end
      rescue Memcached::NotFound
        # Attribute hasn't been stored yet.
        save_to_cache(get_memcache_key, @attributes)
      rescue Memcached::NotStored
        # Attribute was modified before it could write.
        retry
      end
    end
  rescue Exception => e
    Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"

    SqsGen2.new.queue(QueueNames::FAILED_SDB_SAVES).send_message(self.serialize)
  ensure
    Rails.logger.flush
  end
  
  ##
  # Returns the sdb box usage since this object was created.
  def box_usage
    'not implemented'
    #@base.box_usage
  end
  
  ##
  # Gets value(s) for a given attribute name.
  def get(attr_name, options = {})
    force_array = options.delete(:force_array) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    attr_array = @attributes[attr_name]
    attr_array = Array(attr_array) if force_array
    
    unless @attributes[attr_name]
      return attr_array
    end
    
    if not force_array and @attributes[attr_name].first.length >= 1000
      joined_value = ''
      while @attributes[attr_name] && @attributes[attr_name].first.length >= 1000 do
        joined_value += @attributes[attr_name].first
        attr_name += '_'
      end
      
      joined_value += @attributes[attr_name].first if @attributes[attr_name]
      
      return unescape_specials(joined_value)
    end
    
    if not force_array and attr_array.length == 1
      return unescape_specials(attr_array[0])
    end
    
    attr_array.map! do |value|
      unescape_specials(value)
    end
    
    return attr_array
  end
  
  ##
  # Puts a value to be associated with an attribute name.
  def put(attr_name, value, options = {})
    replace = options.delete(:replace) { true }
    cgi_escape = options.delete(:cgi_escape) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    return if value.nil?
    value = value.to_s
    
    # Probably not necessary, because params with questionable characters should call with cgi_escape => true
    #illegal_xml_chars = /\x00|\x01|\x02|\x03|\x04|\x05|\x06|\x07|\x08|\x0B|\x0C|\x0E|\x0F|\x10|\x11|\x12|\x13|\x14|\x15|\x16|\x17|\x18|\x19|\x1A|\x1B|\x1C|\x1D|\x1E|\x1F|\x7F-\x84\x86-\x9F/
    #value = value.to_s.toutf16.gsub(illegal_xml_chars,'')
    
    value = escape_specials(value, {:cgi_escape => cgi_escape})
    
    value_array = Array(value)
    if value.length > 1000
      value_array = value.scan(/.{1,1000}/)
      new_attr_name = attr_name
      
      value_array.each do |part|
        @attributes[new_attr_name] = Array(part)
        @attributes_to_replace[new_attr_name] = Array(part)
        new_attr_name += '_'
      end
      
      #erase all attributes after new_attr_name + '_'
      while @attributes[new_attr_name] do
        delete(new_attr_name, @attributes[new_attr_name].first)
        new_attr_name += '_'
      end
      
      return
    else
      
      new_attr_name = attr_name + '_'
      
      #erase all attributes after new_attr_name + '_'
      while @attributes[new_attr_name] do
        delete(new_attr_name, @attributes[new_attr_name].first)
        new_attr_name += '_'
      end
      
    end
    

    if replace
      @attributes[attr_name] = value_array
      @attributes_to_replace[attr_name] = value_array
    else
      @attributes[attr_name] = value_array | Array(@attributes[attr_name])
      @attributes_to_add[attr_name] = value_array | Array(@attributes_to_add[attr_name])
    end
  end
  
  ##
  # Adds a value to be deleted. Also removes it from the hash of attributes.
  def delete(attr_name, value)
    @attributes_to_delete[attr_name] = Array(value) | Array(@attributes_to_delete[attr_name])
    
    if @attributes[attr_name]
      @attributes[attr_name].delete(value)
      @attributes.delete(attr_name) if @attributes[attr_name].empty?
    end
  end
  
  ##
  # Deletes this entire row immediately (no need to call save after calling this).
  def delete_all
    # TODO: Update memcache as well.
    @@sdb.delete_attributes(@domain_name, @key)
  end
  
  ##
  # Performs a batch_put_attributes.
  def self.put_items(items, options = {})
    replace = options.delete(:force_array) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    raise "Too many items to batch_put" if items.length >25
    return {} if items.length == 0

    domain_name = items[0].domain_name
    items_object = {}
    items.each do |item|
      raise "All domain names must be the same for batch_put_attributes" if item.domain_name != domain_name
      items_object[item.key] = item.attributes
    end
    return @@sdb.batch_put_attributes(domain_name, items_object, replace)
  end
  
  ##
  # Runs a select count(*) for the specified domain, with the specified where clause,
  # and returns the number.
  def self.count(domain_name, where = nil)
    domain_name = get_real_domain_name(domain_name)
    where_clause = where ? "where #{where}" : ''
    next_token = nil
    count = 0
    iterations = 0
    begin 
      iterations += 1
      response = @@sdb.select("select count(*) from `#{domain_name}` #{where_clause}", next_token)
      count += response[:items][0]['Domain']['Count'][0].to_i
      next_token = response[:next_token]
    end while next_token and iterations < 100
    if iterations == 100
      Rails.logger.warn 'Iterations hit max'
    end
    return count
  end
  
  ##
  # Returns an array of items which match the specified select 
  def self.select(domain_name, item = '*', where = nil, order = nil, next_token = nil)
    domain_name = get_real_domain_name(domain_name)
    query = "SELECT #{item} FROM `#{domain_name}`"
  
    query = query + " WHERE #{where}" if where
    query = query + " ORDER BY #{order}" if order
    
    response = @@sdb.select(query, next_token)
    
    sdb_item_array = []
    response[:items].each do |item|
      sdb_item = SimpledbResource.new(domain_name, item.keys[0], {:load => false})
      sdb_item.attributes = item.values[0]
      sdb_item_array.push(sdb_item)
    end
    
    return {
      :items => sdb_item_array,
      :next_token => response[:next_token],
      :box_usage => response[:box_usage]
    }
    
  rescue => e
    Rails.logger.error("Bad select query: #{query}")
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
  def serialize
    {:domain => @domain_name, :key => @key, :attrs => @attributes}.to_json
  end
  
  ##
  # Re-creates this item from a json string.
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    attributes = json['attrs']
    domain_name = json['domain']
    
    item = SimpledbResource.new(domain_name, key, {:load => false})
    item.attributes = attributes
    
    return item
  end
  
  private
  
  def load_from_sdb
    attributes = {}
    begin
      response = @@sdb.get_attributes(@domain_name, @key)
      attributes = response[:attributes]
    rescue AwsError => e
      if e.message.starts_with?("NoSuchDomain")
        Rails.logger.info "NoSuchDomain: #{@domain_name}, when attempting to load #{@key}"
        # Domain will be created on save.
      elsif e.message =~ /getaddrinfo/
        # Attempt to reload?
        raise e
      else
        raise e
      end
    end
    attributes
  end
  
  def get_memcache_key
    "sdb.#{@domain_name}.#{@key}"
  end
  
  # Return the domain name, but strip any pre-existing run mode prefix, in order to ensure that
  # only one prefix is added.
  def self.get_real_domain_name(domain_name)
    RUN_MODE_PREFIX + domain_name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
  end
  
  def get_real_domain_name(domain_name)
    SimpledbResource.get_real_domain_name(domain_name)
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
  
end