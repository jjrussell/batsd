module MemcachedHelper
  include TimeLogHelper
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is saved and returned.
  def get_from_cache_and_save(key, cache = CACHE)
    value = get_from_cache(key, cache) do
      yield
    end
    
    save_to_cache(key, value, cache)
    return value
  end
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is returned.
  def get_from_cache(key, cache = CACHE)
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
  def save_to_cache(key, value, cache = CACHE, time = 1.hour)
    if value
      time_log("Wrote to memcache") do
        cache.set(key, value, time)
      end
    end
  rescue => e
    Rails.logger.info "Memcache exception when setting key #{key}. Error: #{e}"
  end
end
