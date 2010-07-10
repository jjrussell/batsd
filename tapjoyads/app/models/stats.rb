class Stats < SimpledbResource
  
  self.domain_name = 'stats'

  ##
  # Gets the hourly stats for a stat type, from memcache and simpledb.
  # stat_name: The stat name to get.
  # cache_hours: The number of hours in the past to look in memcache for stats. If set to 0, no stats
  #     will be retrieved from memcache.
  def get_hourly_count(stat_name, cache_hours = 2)
    hourly_stats_string = get(stat_name)
    if hourly_stats_string
      hourly_stats = hourly_stats_string.split(',').map{|n| n.to_i}
    else
      hourly_stats = Array.new(24, 0)
    end
    
    if stat_name == 'overall_store_rank'
      return hourly_stats_string ? hourly_stats_string.split(',') : Array.new(24, '0')
    end
    
    now = Time.now.utc
    date, app_id = parse_key
    24.times do |i|
      time = date + i.hours
      if hourly_stats[i] == 0 and time <= now and time >= (now - cache_hours.hours)
        hourly_stats[i] = Mc.get_count(Stats.get_memcache_count_key(stat_name, app_id, time))
      end
    end
    
    return hourly_stats
  end
  
  ##
  # Gets the memcache key for a specific stat_name and app_id. The key will be unique for the hour.
  def self.get_memcache_count_key(stat_name, app_id, time)
    "stats.#{stat_name}.#{app_id}.#{(time.to_i / 1.hour).to_i}"
  end
  
  ##
  # Updates the count of a stat for a given hour.
  def update_stat_for_hour(stat_name, hour, count)
    hour_counts = (get(stat_name) || Array.new(24, '0').join(',')).split(',')
    hour_counts[hour] = count.to_s
    put(stat_name, hour_counts.join(','))
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