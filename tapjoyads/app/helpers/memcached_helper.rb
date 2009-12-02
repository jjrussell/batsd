module MemcachedHelper
  include TimeLogHelper
  
  CACHE = Memcached.new(MEMCACHE_SERVERS, {
    :support_cas => true, 
    :prefix_key => RUN_MODE_PREFIX
    })
  
  unless ENV['RAILS_ENV'] == 'production'
    CACHE.flush
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
    cache = clone ? CACHE.clone : CACHE
    
    value = nil
    time_log("Read from memcache") do
      begin
        value = cache.get(key)
        Rails.logger.info("Memcache key found: #{key}")
      rescue Memcached::NotFound
        Rails.logger.info("Memcache key not found: #{key}")
      rescue Memcached::ServerIsMarkedDead => e
        Rails.logger.info("Memcache::ServerIsMarkedDead: #{key}")
      rescue Memcached::NoServersDefined => e
        Rails.logger.info("Memcache::NoServersDefined: #{e}")
      rescue Memcached::ATimeoutOccurred => e
        Rails.logger.info("ATimeoutOccurred::NoServersDefined: #{e}")
      rescue Memcached::SystemError => e
        Rails.logger.info("Memcache::SystemError: #{e.message}")
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
    cache = clone ? CACHE.clone : CACHE
    
    if value
      time_log("Wrote to memcache") do
        cache.set(key, value, time)
      end
    end
  rescue => e
    Rails.logger.info "Memcache exception when setting key #{key}. Error: #{e}"
  end
  
  def clone
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
