require 'logging'

class Mc

  def self.reset_connection
    options = {
      :support_cas      => true,
      :prefix_key       => RUN_MODE_PREFIX,
      :auto_eject_hosts => false,
      :cache_lookups    => false
    }

    @cache              = Memcached.new(MEMCACHE_SERVERS, options)
    @distributed_caches = DISTRIBUTED_MEMCACHE_SERVERS.map { |server| Memcached.new(server, options) }
  end

  class << self
    attr_accessor :cache, :distributed_caches
  end
  self.reset_connection

  # Memcache counts can't go below 0. Set the offset to 2^32/2 for all counts.
  COUNT_OFFSET = 2147483648
  MAX_KEY_LENGTH = 250

  MEMCACHED_ACTIVE_RECORD_MODELS = %w(App Currency Offer SurveyOffer VideoOffer ReengagementOffer)

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
  def self.get(keys, clone = false, caches = nil, &block)
    keys = keys.to_a
    key  = keys.shift
    caches ||= [ @cache ]
    #We use missing_caches to make sure to distribute data in the event of a miss
    missing_caches = []

    #We use this for looping on the current key with the list of available caches
    available_caches = caches.clone

    value = nil
    log_info_with_time("Read from memcache") do
      begin
        #Grab a cache to try
        cache = available_caches.shift
        #"Key: #{cache_key(key)} ::: Value #{cache.get(cache_key(key))}"
        unless cache.nil?
          cache = cache.clone if clone
          value = cache.get(cache_key(key))
          value.ensure_utf8_encoding! if value.respond_to? :ensure_utf8_encoding!
          Rails.logger.info("Memcache key found: #{key}")
        end
      rescue Memcached::NotFound
        missing_caches << cache
        Rails.logger.info("Memcache key not found in cache, retrying: #{key}")
        retry
      rescue Memcached::ServerIsMarkedDead => e
        Rails.logger.info("Memcached::ServerIsMarkedDead: #{key}")
        retry
      rescue Memcached::ServerError => e
        Rails.logger.info("Memcached::ServerError: #{e.message}")
        retry
      rescue Memcached::NoServersDefined => e
        Rails.logger.info("Memcached::NoServersDefined: #{e}")
      rescue Memcached::ATimeoutOccurred => e
        Rails.logger.info("Memcached::ATimeoutOccurred: #{e}")
      rescue Memcached::SystemError => e
        Rails.logger.info("Memcached::SystemError: #{e.message}")
      rescue ArgumentError => e
        if e.message.match /undefined class\/module (.+)$/
          $1.constantize
          retry
        end
        Rails.logger.info("ArgumentError: #{e.message}")
      end
    end

    unless value.nil? || missing_caches.empty?
      missing_caches.each do |cache|
        # The default is 1.week.  The memcached library doesn't give us the expiration
        # information for keys, so these will just have to be refreshed
        begin
          Mc.add(key, value, clone, 1.week, cache)
        rescue Memcached::NotStored
          # Refilling a cache server, someone must have done it already
        rescue Memcached::ServerError
          # This cache server probably can't fit the key, ignore for now
        end
      end
    end

    if value.nil?
      if keys.present?
        value = Mc.get(keys, clone, caches, &block)
      elsif block_given?
        value = yield
      end
    end

    value
  end

  def self.distributed_get(key, clone = false)
    value = Mc.get(key, clone, @distributed_caches.shuffle) do
      yield if block_given?
    end

    if value.is_a? String
      begin
        Marshal.restore_with_ensure_utf8(value)
      rescue TypeError
        value
      end
    else
      value
    end
  end

  # Adds the value to memcached, not replacing an existing value
  def self.add(key, value, clone = false, time = 1.week, cache = nil)
    if value
      cache ||= @cache
      cache = cache.clone if clone

      log_info_with_time("Added to memcache: #{key}") do
        cache.add(cache_key(key), value, time.to_i)
      end
    end
  end

  ##
  # Saves value to memcached, as long as value is not nil.
  def self.put(key, value, clone = false, time = 1.week, cache = nil)
    if value
      cache ||= @cache
      cache = cache.clone if clone

      log_info_with_time("Wrote to memcache: #{key}") do
        cache.set(cache_key(key), value, time.to_i)
      end
    end
  end

  class << self
    alias_method :set, :put # for rollout
  end

  def self.distributed_put(key, value, clone = false, time = 1.week)
    if value
      errors = []
      log_info_with_time("Wrote to memcache - distributed") do
        @distributed_caches.each do |cache|
          begin
            Mc.put(key, value, clone, time, cache)
          rescue Exception => e
            errors << e
          end
        end
      end

      raise errors.first if errors.length == @distributed_caches.length
    end
  end

  def self.increment_count(key, clone = false, time = 1.week, offset = 1)
    cache = clone ? @cache.clone : @cache
    key = cache_key(key)

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
    cache = clone ? @cache.clone : @cache
    key = cache_key(key)

    begin
      count = cache.get(key, false).to_i
    rescue Memcached::NotFound
      count = COUNT_OFFSET
    end

    return count - COUNT_OFFSET
  end

  def self.compare_and_swap(key, clone = false)
    cache = clone ? @cache.clone : @cache
    key = cache_key(key)

    retries = 2
    begin
      cache.cas(key) do |mc_val|
        yield mc_val
      end
    rescue Memcached::NotFound
      # Attribute hasn't been stored yet.
      cache.set(key, yield(nil))
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
    cache ||= @cache
    cache = cache.clone if clone
    key = cache_key(key)

    begin
      cache.delete(key)
    rescue Memcached::NotFound
      Rails.logger.info("Memcached::NotFound when deleting.")
    end
  end

  def self.distributed_delete(key, clone = false)
    @distributed_caches.each do |cache|
      Mc.delete(key, clone, cache) rescue nil
    end
    nil
  end

  def self.flush(totally_serious)
    @cache.flush if totally_serious == 'totally_serious'
  end

  def self.cache_key(key)
    CGI::escape(key)[0...MAX_KEY_LENGTH]
  end
end
