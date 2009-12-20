class Stats < SimpledbResource
  include MemcachedHelper

  def initialize(key, options = {})
    super 'stats', key, options
  end
  
  ##
  # Gets the hourly stats for a stat type, from memcache and simpledb.
  def get_hourly_count(stat_name)
    hourly_stats_string = get(stat_name)
    if hourly_stats_string
      hourly_stats = hourly_stats_string.split(',').map{|n| n.to_i}
    else
      hourly_stats = Array.new(24, 0)
    end
    
    now = Time.now.utc
    date, app_id = parse_key
    24.times do |i|
      time = date + i.hours
      if hourly_stats[i] == 0 and time <= now
        hourly_stats[i] = get_count_in_cache(Stats.get_memcache_count_key(stat_name, app_id, time))
      end
    end
    
    return hourly_stats
  end
  
  ##
  # Gets the memcache key for a specific stat_name and app_id. The key will be unique for the hour.
  def self.get_memcache_count_key(stat_name, app_id, time)
    "stats.#{stat_name}.#{app_id}.#{(time.to_i / 1.hour).to_i}"
  end
  
  private
  
  ##
  # Returns a couplet, the date and the app_id (or campaign_id), as parsed from the row key.
  def parse_key
    parts = @key.split('.')
    date_parts = parts[1].split('-')
    date = Time.utc(date_parts[0], date_parts[1], date_parts[2])
    
    return date, parts[2]
  end
end