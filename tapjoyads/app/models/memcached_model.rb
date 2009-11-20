class MemcachedModel
  include Singleton
  include TimeLogHelper
  include Ec2Helper
  
  SERVER_LIST_FILE_LOCATION = 'tmp/memcached_servers'
  
  def initialize
    @cache = Memcached.new('')
    @last_update_time = 0
  end
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is saved and returned.
  def get_from_cache_and_save(key, clone = false)
    value = get_from_cache(key, clone) do
      yield
    end
    
    save_to_cache(key, value, clone)
    return value
  end
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is returned.
  def get_from_cache(key, clone = false)
    cache = clone ? @cache.clone : @cache
    #check_servers(cache)
    
    value = nil
    time_log("Read from memcache") do
      begin
        value = cache.get(key)
        Rails.logger.info("Memcache key found: #{key}")
      rescue Memcached::NotFound
        Rails.logger.info("Memcache key not found: #{key}")
      rescue Memcached::ServerIsMarkedDead
        Rails.logger.info("Memcache::ServerIsMarkedDead: #{key}")
      rescue Memcached::NoServersDefined
        Rails.logger.info("Memcache::NoServersDefined: #{key}")
      end
    end
    
    unless value
      value = yield
    end
    
    return value
  end
  
  ##
  # Saves value to memcached, as long as value is not nil.
  def save_to_cache(key, value, clone = false, time = 1.hour)
    cache = clone ? @cache.clone : @cache
    #check_servers(cache)
    
    if value
      time_log("Wrote to memcache") do
        cache.set(key, value, time)
      end
    end
  rescue => e
    Rails.logger.info "Memcache exception when setting key #{key}. Error: #{e}"
  end
  
  ##
  # Registers this cache object with all memcache servers in the cloud.
  def register_servers(cache = nil)
    cache = @cache unless cache
    time_log("Registered memcached servers") do
      dns_names = []
      if ENV['RAILS_ENV'] == 'production'
        dns_names = get_local_dns_names('mc')
      elsif ENV['RAILS_ENV'] == 'test'
        dns_names = get_local_dns_names('testserver')
      else
        dns_names = ['127.0.0.1']
      end
    
      cache.reset dns_names

      server_list_file = File.new(SERVER_LIST_FILE_LOCATION, 'w')
      server_list_file.puts dns_names.split("\n")
      server_list_file.close
    
      @last_update_time = Time.now
    end
  end
  
  ##
  # Clones this cache object.
  def clone
    @cache = @cache.clone
  end
  
  ##
  # Returns the list of memcached servers currently registered.
  def servers
    @cache.servers
  end
  
  private
  
  def check_servers(cache)
    # This extra log line is here in order to debug if this check causes lockups. If it does
    # cause a lockup, this will be the last thing logged.
    Rails.logger.info("Checking memcached servers")
    
    time_log("Checked memcached servers") do
      if cache.servers.empty?
        register_servers(cache)
        return
      end
    
      if File.mtime(SERVER_LIST_FILE_LOCATION) > @last_update_time
        Rails.logger.info "Memcache server update found"
        servers = IO.read(SERVER_LIST_FILE_LOCATION).split("\n")
        cache.reset servers
        @last_update_time = Time.now
      end
    end
  end
  
end
