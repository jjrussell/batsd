require 'logging'

class Mc
  def self.dalli_opts
    @dalli_opts ||= {
      namespace: RUN_MODE_PREFIX,
      async: ENV['ASYNC'],
      socket_max_failures: 2,
      cache_lookups: false,
      down_retry_delay: 300
    }
  end

  def self.reset_connection
    @cache              = Dalli::Client.new(MEMCACHE_SERVERS, dalli_opts)
    @distributed_caches = DISTRIBUTED_MEMCACHE_SERVERS.map do |server|
      Dalli::Client.new(server, dalli_opts)
    end
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

    # We use missing_caches to make sure to distribute data in the event of a miss
    missing_caches = []

    # We might not find the value, we'll keep a string to log
    fail_reason = nil

    value = nil
    log_info_with_time("Read from memcache") do
      # Loop over caches looking for our key
      caches.each do |cache|
        cache = cache.clone if clone
        begin
          cache.get(cache_key(key)).tap do |val|
            # If we didn't find the key in this cache, hang on to it
            # so we can write the value if we find it in another cache
            if val
              val.ensure_utf8_encoding! if val.respond_to?(:ensure_utf8_encoding!)
              Rails.logger.info("Memcache key found: #{key}")
              value = val
              break
            else
              missing_caches << cache
              Rails.logger.info("Memcache key not found in cache, retrying: #{key}")
              next # try next cache
            end
          end
        rescue Dalli::RingError => e
          fail_reason = "Dalli::RingError: #{key}"
          next
        rescue Dalli::DalliError => e
          fail_reason = "Dalli::DalliError: #{e.message}"
          next
        rescue Dalli::NetworkError => e
          fail_reason = "Dalli::NetworkError: #{e}"
        rescue ArgumentError => e
          if e.message.match /undefined class\/module (.+)$/
            $1.constantize
            retry
          end
          fail_reason = "ArgumentError: #{e.message}"
        end
      end
    end

    Rails.logger.debug "I think val is #{value}"

    fail_reason and Rails.logger.info(fail_reason) # value.nil? => true

    unless value.nil? || missing_caches.empty?
      missing_caches.each do |cache|
        # The default is 1.week.  The memcached library doesn't give us the expiration
        # information for keys, so these will just have to be refreshed
        Mc.add(key, value, clone, 1.week, cache)
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

    if offset > 0
      count = cache.incr(key, offset)
    else
      count = cache.decr(key, -offset)
    end

    unless count
      count = offset + COUNT_OFFSET
      cache.set(key, count.to_i, time.to_i, raw: true)
    end

    count - COUNT_OFFSET
  end

  def self.get_count(key, clone = false)
    cache = clone ? @cache.clone : @cache
    key = cache_key(key)

    count = cache.get(key, false) || COUNT_OFFSET
    count.to_i - COUNT_OFFSET
  end

  def self.compare_and_swap(key, clone = false)
    cache = clone ? @cache.clone : @cache
    key = cache_key(key)
    success = nil

    retries = 5
    retries.times do
      success = cache.cas(key) do |mc_val|
        mc_val.nil? ? success = nil : yield(mc_val)
      end

      if success.nil?
        cache.set(key, yield(nil))
        success = true
      end

      break if success
    end

    success or raise Dalli::DalliError
  end

  def self.delete(key, clone = false, cache = nil)
    cache ||= @cache
    cache = cache.clone if clone

    cache.delete(cache_key(key))
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
