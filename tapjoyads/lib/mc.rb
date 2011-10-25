class Mc

  def self.reset_connection
    options = {
      :support_cas      => true,
      :prefix_key       => RUN_MODE_PREFIX,
      :auto_eject_hosts => false,
      :cache_lookups    => false
    }
    @@cache = Memcached.new(MEMCACHE_SERVERS, options)
    @@individual_caches = MEMCACHE_SERVERS.map do |server|
      Memcached.new(server, options)
    end
  end

  cattr_accessor :cache, :individual_caches
  self.reset_connection

  # Memcache counts can't go below 0. Set the offset to 2^32/2 for all counts.
  COUNT_OFFSET = 2147483648

  MEMCACHED_ACTIVE_RECORD_MODELS = %w( App Currency Offer )

  def self.cache_all
    MEMCACHED_ACTIVE_RECORD_MODELS.each do |klass|
      klass.constantize.cache_all
    end
  end

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

    if did_yield
      Mc.put(key, value, clone, time) rescue nil
    end
    return value
  end

  def self.distributed_get_and_put(key, clone = false, time = 1.week)
    did_yield = false
    value = Mc.distributed_get(key, clone) do
      did_yield = true
      yield
    end

    if did_yield
      Mc.distributed_put(key, value, clone, time) rescue nil
    end
    return value
  end

  ##
  # Gets object from cache which matches key.
  # If no object is found, then control is yielded, and the object
  # returned from the yield block is returned.
  def self.get(key, clone = false, cache = nil)
    cache ||= @@cache
    cache = cache.clone if clone

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

  def self.distributed_get(key, clone = false)
    cache_num = rand(@@individual_caches.size)

    value = Mc.get(key, clone, @@individual_caches[cache_num]) do
      yield if block_given?
    end

    return value
  end

  ##
  # Saves value to memcached, as long as value is not nil.
  def self.put(key, value, clone = false, time = 1.week, cache = nil)
    if value
      cache ||= @@cache
      cache = cache.clone if clone

      Rails.logger.info_with_time("Wrote to memcache: #{key}") do
        cache.set(CGI::escape(key), value, time.to_i)
      end
    end
  end

  def self.distributed_put(key, value, clone = false, time = 1.week)
    if value
      begin
        Rails.logger.info_with_time("Wrote to memcache - distributed") do
          @@individual_caches.each do |cache|
            Mc.put(key, value, clone, time, cache)
          end
        end
      rescue Exception => e
        Mc.distributed_delete(key, clone)
        raise e
      end
    end
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
      cache.set(key, count.to_s, time.to_i, false)
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

    retries = 2
    begin
      c.cas(key) do |mc_val|
        yield mc_val
      end
    rescue Memcached::NotFound
      # Attribute hasn't been stored yet.
      c.set(key, yield(nil))
    rescue Memcached::ConnectionDataExists => e
      # Attribute was modified before it could write.
      if retries > 0
        retries -= 1
        retry
      else
        raise e
      end
    end
  end

  def self.delete(key, clone = false, cache = nil)
    cache ||= @@cache
    cache = cache.clone if clone
    key = CGI::escape(key)

    begin
      cache.delete(key)
    rescue Memcached::NotFound
      Rails.logger.debug("Memcached::NotFound when deleting.")
    end
  end

  def self.distributed_delete(key, clone = false)
    @@individual_caches.each do |cache|
      Mc.delete(key, clone, cache) rescue nil
    end
    nil
  end

end
