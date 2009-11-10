module MemcachedHelper
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is saved and returned.
  def get_from_cache_and_save(key)
    value = get_from_cache(key) do
      yield
    end
    
    save_to_cache(key, value)
    return value
  end
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is returned.
  def get_from_cache(key)
    value = nil
    begin
      value = CACHE.get(key)
      logger.debug("Memcache key found: #{key}")
    rescue Memcached::NotFound
      logger.debug("Memcache key not found: #{key}")
    rescue Memcached::ServerIsMarkedDead
      logger.debug("Memcache::ServerIsMarkedDead: #{key}")
    end
    
    unless value
      value = yield
    end
    
    return value
  end
  
  ##
  # Saves value to memcached, as long as value is not nil.
  def save_to_cache(key, value, time = 1.hour)
    if value
      CACHE.set(key, value, time)
    end
  end
end
