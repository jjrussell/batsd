class Stats < SimpledbResource
  
  self.domain_name = 'stats'

  self.sdb_attr :values, :type => :json, :default_value => {}
  
  attr_reader :parsed_values

  STAT_TYPES = ['logins', 'hourly_impressions', 'paid_installs', 
      'installs_spend', 'paid_clicks', 'new_users', 'ratings', 'offers',
      'offers_revenue', 'installs_revenue', 'published_installs',
      'offers_opened', 'installs_opened', 'daily_active_users', 
      'monthly_active_users', 'vg_purchases', 'offerwall_views',
      'display_ads_requested', 'display_ads_shown', 'display_clicks', 'display_conversions',
      'display_revenue', 'jailbroken_installs', 'ranks']

  def after_initialize
    if (values.blank?)
      convert_to_new_format
    end
    @parsed_values = values
    @parsed_values['ranks'] = {} if @parsed_values['ranks'].blank?
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
    self.values = @parsed_values
  end

  ##
  # Populates the daily_stat_row from an hourly_stat_row.
  # hourly_stat_row: Source of data.
  # day: The 0-based day of the month in which to populate.
  def populate_daily_from_hourly(hourly_stat_row, day)
    hourly_stat_row.parsed_values.each do |key, value|
      if key == 'ranks'
        value.each do |rank_key, rank_value|
          stat_path = ['ranks', rank_key]
          count = rank_value.reject{|r| r == 0 || r.nil?}.min
          update_stat_for_day(stat_path, day, count)
        end
      else
        count = value.sum
        update_stat_for_day(key, day, count)
      end
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
    self.values = @parsed_values
    super(options)
  end
  
private

  def strip_defaults(hash)
    hash.each do |key, value|
      if value.is_a?(Array)
        hash.delete(key) if value.all? { |i| i.nil? || i == 0 }
      else
        strip_defaults(value)
      end
    end
  end

  def get_counts_object(stat_name_or_path, length)
    obj = @parsed_values
    Array(stat_name_or_path)[0..-2].each do |key|
      obj[key] = {} if obj[key].nil?
      obj = obj[key]
    end
    key = Array(stat_name_or_path).last
    
    default_value = Array(stat_name_or_path).first == 'ranks' ? nil : 0
    
    obj[key] = Array.new(length, default_value) if obj[key].nil?
    obj[key]
  end
  
  ##
  # Converts this to new format. The old format stores each stat as a separate attribute, the new format
  # stores all stats in single 'values' json attribute. The new format allows for more than 255 stats
  # to be stored per row. It also allows for a hierarchy, which is used for ranks.
  #
  # TO REMOVE: Temporary method. Remove after all stats are converted.
  def convert_to_new_format
    @parsed_values = {}
    @parsed_values['ranks'] = {}
    
    ["rewards_opened", "rewards", "rewards_revenue"].each do |stat_name|
      delete(stat_name) if get(stat_name).present?
    end
    
    Stats::STAT_TYPES.each do |stat_name|
      stat_name = 'overall_store_rank' if stat_name == 'ranks'
      
      counts = get(stat_name) || ''
      delete(stat_name) if get(stat_name).present?
      
      counts = counts.split(',').map do |count|
        if stat_name == 'overall_store_rank'
          (count == '0' || count == '-') ? nil : count.to_i
        else
          count == '-' ? nil : count.to_i
        end
      end
      
      skip = true
      counts.each do |count|
        if count.present? && count != 0
          skip = false
        end
      end
      next if skip
      
      if stat_name == 'overall_store_rank'
        @parsed_values['ranks']['overall.free.united_states'] = counts
      else
        @parsed_values[stat_name] = counts        
      end
    end
    
    @attributes.keys.each do |key|
      delete(key) unless key == 'updated-at' || key == 'values'
    end
    
    self.values = @parsed_values
  end
end