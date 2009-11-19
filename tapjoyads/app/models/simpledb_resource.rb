require 'sdb_batchput'
require 'activemessaging/processor'

class SimpledbResource  
  include TimeLogHelper
  include RightAws
  include ActiveMessaging::MessageSender
  
  attr_accessor :domain_name, :key, :attributes
  
  @@sdb = SdbInterface.new(ENV['AMAZON_ACCESS_KEY_ID'], ENV['AMAZON_SECRET_ACCESS_KEY'], 
      {:multi_thread => true})
  
  ##
  # Initializes a new SimpledbResource, which represents a single row in a domain.
  # domain_name: The name of the domain
  # key: The item key
  # load: Whether the item attributes should be laoded at all.
  def initialize(domain_name, key, load = true)
    # Set the domain name, but strip any pre-existing run mode prefix, in order to ensure that
    # only one prefix is added.
    @domain_name = RUN_MODE_PREFIX + domain_name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
    @key = key
    @attributes = {}
    
    if load
      load()
    end
  end
  
  ##
  # Attempt to load the item attributes from memcache. If they are not found,
  # they will attempt be loaded from simpledb. If thet are still not found,
  # an empty attributes hash will be created.
  def load
    @attributes = MemcachedModel.instance.get_from_cache_and_save(get_memcache_key) do
      response = @@sdb.get_attributes(@domain_name, @key)
      response[:attributes]
    end
  rescue AwsError => e
    if e.message.starts_with?("NoSuchDomain")
      Rails.logger.info "NoSuchDomain: #{@domain_name}, when attempting to load #{@key}"
      # Do nothing. Attributes will remain defined as {}. Domain will be created on save.
    else
      raise e
    end
    
  end
  
  ##
  # Updates the 'updated-at' attribute of this item, and saves it to SimpleDB.
  # If the domain does not exist, then the domain is created.
  # write_to_memcache: Whether to write these attributes to memcache.
  # replace: Whether to replace attribute values with identical names. It is important to note that
  #     if load() has not been called, and replace is set to true, it is possible to overwrite
  #     attribute values.
  def save(write_to_memcache = true, replace = true)
    time_log("Spawing thread") do
      Thread.new do
        Rails.logger.info "Saving to #{@domain_name}"
        
        time_log("Saving to sdb") do
          put('updated-at', Time.now.utc.to_f.to_s)
          
          begin
            @@sdb.put_attributes(@domain_name, @key, @attributes, replace)
          rescue AwsError => e
            if e.message.starts_with?("NoSuchDomain")
              time_log("Creating new domain") do
                @@sdb.create_domain(@domain_name)
                @@sdb.put_attributes(@domain_name, @key, @attributes, replace)
              end
            else
              raise e
            end
          end
        end
      
        if write_to_memcache
          MemcachedModel.instance.save_to_cache(get_memcache_key, @attributes, true, 1.hour)
        end
      end
      Rails.logger.flush
    end
  rescue Exception => e
    Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"
    
    publish :failed_sdb_saves, self.serialize
  end
  
  ##
  # Returns the sdb box usage since this object was created.
  def box_usage
    'not implemented'
    #@base.box_usage
  end
  
  ##
  # Gets value(s) for a given attribute name.
  def get(attr_name, force_array = false)
    attr_array = @attributes[attr_name]
    
    if not force_array and not attr_array.nil? and attr_array.length == 1
      return attr_array[0]
    end
      
    return attr_array
  end
  
  ##
  # Puts a value to be associated with an attribute name.
  def put(attr_name, value, replace = true)
    if replace or not @attributes[attr_name]
      @attributes[attr_name] = [value]
    else
      @attributes[attr_name].push(value)
    end
  end
  
  ##
  # Runs a select count(*) for the specified domain, with the specified where clause,
  # and returns the number.
  def self.count(domain, where = nil)
    where_clause = where ? "where #{where}" : ''
    next_token = nil
    count = 0
    iterations = 0
    begin 
      iterations += 1
      response = @@sdb.select("select count(*) from `#{RUN_MODE_PREFIX}#{domain}` #{where_clause}")
      count += response[:items][0]['Domain']['Count'][0].to_i
      next_token = response[:next_token]
    end while not next_token.nil? and iterations < 100
    if iterations == 100
      Rails.logger.warn 'Iterations hit max'
    end
    return count
  end
  
  ##
  # Returns an array of items which match the specified select 
  def self.select(domain, item = '*', where = nil, order = nil, next_token = nil)
    query = "SELECT #{item} FROM `#{RUN_MODE_PREFIX}#{domain}`"
  
    query = query + " WHERE #{where}" if where
    query = query + " ORDER BY #{order}" if order
    
    response = @@sdb.select(query, next_token)
    
    sdb_item_array = []
    response[:items].each do |item|
      sdb_item = SimpledbResource.new(domain, item.keys[0], false)
      sdb_item.attributes = item.values[0]
      sdb_item_array.push(sdb_item)
    end
    
    return sdb_item_array
  rescue
    Rails.logger.error("Bad select query: #{query}")
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
    
    item = SimpledbResource.new(domain_name, key, false)
    item.attributes = attributes
    
    return item
  end
  
  private
  
  def get_memcache_key
    "sdb.#{@domain_name}.#{@key}"
  end
end