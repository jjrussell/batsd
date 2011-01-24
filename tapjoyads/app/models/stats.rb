class Stats < SimpledbResource
  
  self.domain_name = 'stats'

  self.sdb_attr :values, :type => :json, :default_value => {}
  self.sdb_attr :ranks, :type => :json, :default_value => {}
  
  attr_reader :parsed_values, :parsed_ranks

  STAT_TYPES = ['logins', 'hourly_impressions', 'paid_installs', 
      'installs_spend', 'paid_clicks', 'new_users', 'ratings', 'offers',
      'offers_revenue', 'installs_revenue', 'published_installs',
      'offers_opened', 'daily_active_users', 
      'monthly_active_users', 'vg_purchases', 'offerwall_views',
      'display_ads_requested', 'display_ads_shown', 'display_clicks', 'display_conversions',
      'display_revenue', 'jailbroken_installs', 'ranks']

  def after_initialize
    @parsed_values = values
    @parsed_ranks = ranks
  end

  ##
  # Gets the hourly stats for a stat type.
  # stat_name_or_path: The stat to get, a string, or an array representing the path.
  def get_hourly_count(stat_name_or_path)
    get_counts_object(stat_name_or_path, 24)
  end
  
  def get_daily_count(stat_name_or_path)
    get_counts_object(stat_name_or_path, 31)
  end
  
  ##
  # Gets the memcache key for a specific stat_name_or_path and app_id. The key will be unique for the hour.
  def self.get_memcache_count_key(stat_name_or_path, app_id, time)
    stat_name_string = Array(stat_name_or_path).join(',')
    "stats.#{stat_name_string}.#{app_id}.#{(time.to_i / 1.hour).to_i}"
  end
  
  ##
  # Updates the count of a stat for a given hour.
  # stat_name_or_path: Which stat to update
  # hour: The 0-based hour of the day.
  # count: The value to set.
  def update_stat_for_hour(stat_name_or_path, hour, count)
    update_stat(stat_name_or_path, hour, count, 24)
  end
  
  ##
  # Updates the count of a stat for a given day.
  # stat_name_or_path: Which stat to update
  # day: The 0-based day of the month.
  # count: The value to set.
  def update_stat_for_day(stat_name_or_path, day, count)
    update_stat(stat_name_or_path, day, count, 31)
  end

  def update_stat(stat_name_or_path, ordinal, count, length)
    counts = get_counts_object(stat_name_or_path, length)
    counts[ordinal] = count
  end

  ##
  # Populates the daily_stat_row from an hourly_stat_row.
  # hourly_stat_row: Source of data.
  # day: The 0-based day of the month in which to populate.
  def populate_daily_from_hourly(hourly_stat_row, day)
    hourly_stat_row.parsed_values.each do |key, value|
      count = value.sum
      update_stat_for_day(key, day, count)
    end
    
    hourly_stat_row.parsed_ranks.each do |key, value|
      stat_path = ['ranks', key]
      rank = value.reject{ |r| r == 0 }.min
      update_stat_for_day(stat_path, day, rank)
    end
  end
  
  ##
  # Returns a couplet, the date and the app_id (or campaign_id), as parsed from the row key.
  def parse_key
    parts = @key.split('.')
    date_parts = parts[1].split('-')
    date = Time.utc(date_parts[0], date_parts[1], date_parts[2])
    
    return date, parts[2]
  end
  
  def serial_save(options = {})
    strip_defaults(@parsed_values)
    strip_defaults(@parsed_ranks)
    
    self.values = @parsed_values if self.values != @parsed_values
    self.ranks = @parsed_ranks if self.ranks != @parsed_ranks
    
    super(options) if changed?
  end
  
private

  def strip_defaults(hash)
    hash.each do |key, value|
      hash.delete(key) if value.uniq == [0]
    end
  end

  def get_counts_object(stat_name_or_path, length)
    if stat_name_or_path == 'ranks'
      return @parsed_ranks
    elsif Array(stat_name_or_path).first == 'ranks'
      obj = @parsed_ranks
    else
      obj = @parsed_values
    end
    
    key = Array(stat_name_or_path).last
    
    obj[key] = Array.new(length, 0) if obj[key].nil?
    obj[key]
  end
end