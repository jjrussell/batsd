class SupportRequestStats
  PREFIX = 'support_request_stats:'
  HOURS_CACHED = [24, 12, 1]
  STATS = %w(last_updated total offers publisher_apps udids tapjoy_device_ids)

  # Cache the past X hours, where X is a number in HOURS_CACHED
  #
  # @force [Boolean] if set, re-cache everything, even if it has been set less
  # than 30 minutes ago.
  def self.cache_all(force = false)
    HOURS_CACHED.each do |h|
      last_updated = $redis.get "#{prefix(h)}last_updated"
      if last_updated.nil? || force || Time.zone.parse(last_updated) < Time.zone.now - 30.minutes
        cache_past_hours(h)
      end
    end
  end

  # @n [Integer] a number in HOURS_CACHED
  def self.cache_past_hours(n)
    $redis.set "#{prefix(n)}last_updated", Time.zone.now.to_yaml
    start_time = n.hours.ago
    end_time   = Time.zone.now
    cache(start_time, end_time, prefix(n))
  end

  def self.cache(start_time, end_time, key_prefix)
    offer_id_count         = Hash.new(0)
    publisher_app_id_count = Hash.new(0)
    udid_count             = Hash.new(0)
    tapjoy_device_id_count = Hash.new(0)
    total                  = 0
    query = "`updated-at` >= '#{start_time.to_f}' " +
            "AND `updated-at` < '#{end_time.to_f}'"
    SupportRequest.select(:where => query) do |sr|
      offer_id_count[sr.offer_id] += 1
      publisher_app_id_count[sr.app_id] += 1
      udid_count[sr.udid] += 1
      tapjoy_device_id_count[sr.tapjoy_device_id] += 1
      total += 1
    end

    top_offer_ids = sort_by_most_frequently_reported(offer_id_count)[0...25]
    $redis.set "#{key_prefix}offers", top_offer_ids.to_json

    top_publisher_app_ids = sort_by_most_frequently_reported(publisher_app_id_count)[0...25]
    $redis.set "#{key_prefix}publisher_apps", top_publisher_app_ids.to_json

    top_udids = sort_by_most_frequently_reported(udid_count)[0...25]
    $redis.set "#{key_prefix}udids", top_udids.to_json

    top_tapjoy_device_ids = sort_by_most_frequently_reported(tapjoy_device_id_count)[0...25]
    $redis.set "#{key_prefix}tapjoy_device_ids", top_tapjoy_device_ids.to_json

    $redis.set "#{key_prefix}total", total
    $redis.set "#{key_prefix}last_updated", Time.zone.now.to_yaml

    STATS.each { |stat| $redis.expire("#{key_prefix}#{stat}", 2.hours) }
  end

  # Returns statsitics for the past X hours, where X is a number in HOURS_CACHED
  #
  # @hours [Integer] a number in HOURS_CACHED
  # @stat [String] a string in STATS
  # @return [Hash] containing keys for every string in STATS
  def self.for_past(hours)
    unless HOURS_CACHED.include?(hours)
      raise ArgumentError, "past #{hours} not cached"
    end
    result = {}
    STATS.each do |stat|
      stored = $redis.get("#{prefix(hours)}#{stat}")
      result[stat.to_sym] = convert_from_json(stat, stored)
    end
    result
  end

  # Clear cache. Doesn't clear stats set by set_range
  def self.clear_cache
    HOURS_CACHED.each do |h|
      STATS.each { |k| $redis.set "#{prefix(h)}#{k}", nil }
    end
  end

  private
  class << self
    # Generate a hash ordered by the ids most frequently support requested
    # @return [Array] In the format:
    #                 [[offer_id, number_of_support_requests_about_it], ...]
    def sort_by_most_frequently_reported(id_hash)
      # Slower equivalent: offer_id_count.sort_by( |k,v| v}[0...25]
      id_hash.sort{ |a,b| b[1] <=> a[1] }
    end

    def prefix(n)
      "#{PREFIX}#{n}_"
    end

    def convert_from_json(stat, value)
      unless STATS.include?(stat)
        raise ArgumentError, "#{stat} is not a valid statistic"
      end
      value = case stat
      when 'offers', 'publisher_apps', 'udids'
        JSON.parse(value)
      when 'last_updated'
        Time.zone.parse(value)
      when 'total'
        value.to_i
      else value
      end
    end
  end
end
