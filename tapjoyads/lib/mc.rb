class Mc
  cattr_accessor :cache
  
  @@cache = Memcached.new(MEMCACHE_SERVERS, {
    :support_cas => true, 
    :prefix_key => RUN_MODE_PREFIX
    })
    
  # Memcache counts can't go below 0. Set the offset to 2^32/2 for all counts.
  COUNT_OFFSET = 2147483648
  
  ##
  # Gets object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is put into cache and returned.
  def self.get_and_put(key, clone = false, time = 1.week)
    did_yield = false
    value = Mc.get(key, clone) do
      did_yield = true
      yield
    end
    
    Mc.put(key, value, clone, time) if did_yield
    return value
  end
  
  ##
  # Gets object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is returned.
  def self.get(key, clone = false)
    cache = clone ? @@cache.clone : @@cache
    
    value = nil
    Rails.logger.info_with_time("Read from memcache") do
      begin
        value = cache.get(CGI::escape(key))
        Rails.logger.info("Memcache key found: #{key}")
      rescue Memcached::NotFound
        Rails.logger.info("Memcache key not found: #{key}")
      rescue Memcached::ServerIsMarkedDead => e
        Rails.logger.info("Memcached::ServerIsMarkedDead: #{key}")
      rescue Memcached::NoServersDefined => e
        Rails.logger.info("Memcached::NoServersDefined: #{e}")
      rescue Memcached::ATimeoutOccurred => e
        Rails.logger.info("Memcached::ATimeoutOccurred: #{e}")
      rescue Memcached::SystemError => e
        Rails.logger.info("Memcached::SystemError: #{e.message}")
      rescue ArgumentError => e
        Rails.logger.info("ArgumentError: #{e.message}")
      end
    end
    
    if value.nil? && block_given?
      value = yield
    end
    
    return value
  end
  
  ##
  # Saves value to memcached, as long as value is not nil.
  def self.put(key, value, clone = false, time = 1.week)
    cache = clone ? @@cache.clone : @@cache
    
    if value
      Rails.logger.info_with_time("Wrote to memcache") do
        cache.set(CGI::escape(key), value, time)
      end
    end
  rescue => e
    Rails.logger.info "Memcache exception when setting key #{key}. Error: #{e}"
  end
  
  def self.increment_count(key, clone = false, time = 1.week, offset = 1)
    cache = clone ? @@cache.clone : @@cache
    key = CGI::escape(key)
    
    begin
      if offset > 0
        count = cache.increment(key, offset)
      else
        count = cache.decrement(key, -offset)
      end
    rescue Memcached::NotFound
      count = offset + COUNT_OFFSET
      cache.set(key, count, time, false)
    end
    
    return count - COUNT_OFFSET
  end
  
  def self.get_count(key, clone = false)
    cache = clone ? @@cache.clone : @@cache
    key = CGI::escape(key)
    
    begin
      count = cache.get(key, false).to_i
    rescue Memcached::NotFound
      count = COUNT_OFFSET
    end
    
    return count - COUNT_OFFSET
  end

  def self.compare_and_swap(key, clone = false)
    c = clone ? @@cache.clone : @@cache
    key = CGI::escape(key)
    
    begin
      c.cas(key) do |mc_val|
        yield mc_val
      end
    rescue Memcached::NotFound
      # Attribute hasn't been stored yet.
      c.set(key, yield(nil))
    rescue Memcached::NotStored
      # Attribute was modified before it could write.
      retry
    end
  end
  
  def self.delete(key, clone = false)
    cache = clone ? @@cache.clone : @@cache
    key = CGI::escape(key)
    
    begin
      cache.delete(key)
    rescue Memcached::NotFound
      Rails.logger.debug("Memcached::NotFound when deleting.")
    end
  end
  
  def self.reset_connection
    @@cache = @@cache.clone
  end
end