module MemcachedHelper
  include TimeLogHelper
  
  CACHE = Memcached.new(MEMCACHE_SERVERS, {
    :support_cas => true, 
    :prefix_key => RUN_MODE_PREFIX
    })
    
  # Memcache counts can't go below 0. Set the offset to 2^32/2 for all counts.
  COUNT_OFFSET = 2147483648
  
  unless ENV['RAILS_ENV'] == 'production'
    CACHE.flush
  end
  
  class KeyExists < RuntimeError; end
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is saved and returned.
  def get_from_cache_and_save(key, clone = false, time = 1.week)
    did_yield = false
    value = get_from_cache(key, clone) do
      did_yield = true
      yield
    end
    
    save_to_cache(key, value, clone, time) if did_yield
    return value
  end
  
  ##
  # Gets from object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is returned.
  def get_from_cache(key, clone = false)
    cache = clone ? CACHE.clone : CACHE
    
    value = nil
    time_log("Read from memcache") do
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
    
    unless value
      if block_given?
        value = yield
      end
    end
    
    return value
  end
  
  ##
  # Saves value to memcached, as long as value is not nil.
  def save_to_cache(key, value, clone = false, time = 1.week)
    cache = clone ? CACHE.clone : CACHE
    
    if value
      time_log("Wrote to memcache") do
        cache.set(CGI::escape(key), value, time)
      end
    end
  rescue => e
    Rails.logger.info "Memcache exception when setting key #{key}. Error: #{e}"
  end
  
  def increment_count_in_cache(key, clone = false, time = 1.week, offset = 1)
    cache = clone ? CACHE.clone : CACHE
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
    
    # Remove this code once all counters are using COUNT_OFFSET
    return count if count < 1000000
    
    return count - COUNT_OFFSET
  end
  
  def get_count_in_cache(key, clone = false)
    cache = clone ? CACHE.clone : CACHE
    key = CGI::escape(key)
    
    begin
      count = cache.get(key, false).to_i
    rescue Memcached::NotFound
      count = COUNT_OFFSET
    end
    
    # Remove this code once all counters are using COUNT_OFFSET
    return count if count < 1000000
    
    return count - COUNT_OFFSET
  end

  def compare_and_swap_in_cache(key, clone = false)
    cache = clone ? CACHE.clone : CACHE
    key = CGI::escape(key)
    
    begin
      cache.cas(key) do |mc_val|
        yield mc_val
      end
    rescue Memcached::NotFound
      # Attribute hasn't been stored yet.
      cache.set(key, yield(nil))
    rescue Memcached::NotStored
      # Attribute was modified before it could write.
      retry
    end
    
  end
  
  def delete_from_cache(key, clone = false)
    cache = clone ? CACHE.clone : CACHE
    key = CGI::escape(key)
    
    begin
      cache.delete(key)
    rescue Memcached::NotFound
      Rails.logger.debug("Memcached::NotFound when deleting.")
    end
  end
  
  def lock_on_key(key, clone = false)
    cache = clone ? CACHE.clone : CACHE
    key = CGI::escape(key)
    
    begin 
      cache.add(key, 'locked')
      begin
        yield
      ensure
        cache.delete(key)
      end
    rescue Memcached::NotStored
      raise KeyExists.new
    end
  end
  
  module_function
  def reset_connection
    Kernel.with_warnings_suppressed do
      MemcachedHelper.const_set('CACHE', CACHE.clone)
    end
  end
end

module Kernel
  # Suppresses warnings within a given block.
  def with_warnings_suppressed
    saved_verbosity = $-v
    $-v = nil
    yield
  ensure
    $-v = saved_verbosity
  end
end
