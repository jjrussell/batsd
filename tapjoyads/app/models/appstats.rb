class Appstats
  
  attr_accessor :app_key, :stats, :granularity, :start_time, :end_time, :x_labels, :intervals
  
  def initialize(app_key, options = {})
    @app_key = app_key
    
    @now = Time.zone.now
    @granularity = options.delete(:granularity) { :hourly }
    @start_time = options.delete(:start_time) { Time.utc(@now.year, @now.month, @now.day) }
    @end_time = options.delete(:end_time) { @now }
    @stat_types = options.delete(:stat_types) { Stats::STAT_TYPES }
    @include_labels = options.delete(:include_labels) { false }
    cache_hours = options.delete(:cache_hours) { 3 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    @stat_rows = {}
    
    @stats = {}
    @stat_types.each do |stat_type|
      if @granularity == :hourly
        @stats[stat_type] = get_hourly_stats(stat_type, @start_time.utc, @end_time.utc, cache_hours)
      elsif @granularity == :daily
        @stats[stat_type] = get_daily_stats(stat_type, @start_time.utc, @end_time.utc, cache_hours)
      else
        raise "Unsupported granularity"
      end
    end
    
    # Convert 0 ranks to nil.
    if @stats['ranks']
      @stats['ranks'].each do |key, value|
        value.map! { |i| i == 0 ? nil : i }
      end
    end
    
    # cvr
    if @stats['paid_clicks'] and @stats['paid_installs']
      @stats['cvr'] = []
      @stats['paid_clicks'].length.times do |i|
        if @stats['paid_clicks'][i] == 0
          @stats['cvr'][i] = 0
        else
          @stats['cvr'][i] = "%.2f" % (@stats['paid_installs'][i].to_f / @stats['paid_clicks'][i])
        end
      end
    end
    
    # rewards
    if @stats['published_installs'] and @stats['offers']
      @stats['rewards'] = []
      @stats['published_installs'].length.times do |i|
        @stats['rewards'][i] = @stats['published_installs'][i] + @stats['offers'][i]
      end
    end
    
    # rewards_opened
    if @stats['offers_opened']
      @stats['rewards_opened'] = @stats['offers_opened']
    end
    
    # rewards_revenue
    if @stats['installs_revenue'] and @stats['offers_revenue']
      @stats['rewards_revenue'] = []
      @stats['installs_revenue'].length.times do |i|
        @stats['rewards_revenue'][i] = @stats['installs_revenue'][i] + @stats['offers_revenue'][i]
      end
    end
    
    # rewards_ctr
    if @stats['offerwall_views'] and @stats['rewards_opened']
      @stats['rewards_ctr'] = []
      @stats['offerwall_views'].length.times do |i|
        if @stats['offerwall_views'][i] == 0
          @stats['rewards_ctr'][i] = 0
        else
          @stats['rewards_ctr'][i] = @stats['rewards_opened'][i].to_f / @stats['offerwall_views'][i].to_f
        end
      end
    end
    
    # rewards_cvr
    if @stats['rewards_opened'] and @stats['rewards']
      @stats['rewards_cvr'] = []
      @stats['rewards_opened'].length.times do |i|
        if @stats['rewards_opened'][i] == 0
          @stats['rewards_cvr'][i] = 0
        else
          @stats['rewards_cvr'][i] = "%.2f" % (@stats['rewards'][i].to_f / @stats['rewards_opened'][i])
        end
      end
    end
    
    # offerwall_ecpm
    if @stats['offerwall_views'] and @stats['rewards_revenue']
      @stats['offerwall_ecpm'] = []
      @stats['offerwall_views'].length.times do |i|
        if @stats['offerwall_views'][i] == 0
          @stats['offerwall_ecpm'][i] = 0
        else
          @stats['offerwall_ecpm'][i] = @stats['rewards_revenue'][i].to_f / (@stats['offerwall_views'][i] / 1000.0)
        end
      end
    end
    
    # featured_ctr
    if @stats['featured_offers_shown'] and @stats['featured_offers_opened']
      @stats['featured_ctr'] = []
      @stats['featured_offers_shown'].length.times do |i|
        if @stats['featured_offers_shown'][i] == 0
          @stats['featured_ctr'][i] = 0
        else
          @stats['featured_ctr'][i] = @stats['featured_offers_opened'][i].to_f / @stats['featured_offers_shown'][i].to_f
        end
      end
    end
    
    # featured_cvr
    if @stats['featured_offers_opened'] and @stats['featured_published_offers']
      @stats['featured_cvr'] = []
      @stats['featured_offers_opened'].length.times do |i|
        if @stats['featured_offers_opened'][i] == 0
          @stats['featured_cvr'][i] = 0
        else
          @stats['featured_cvr'][i] = @stats['featured_published_offers'][i].to_f / @stats['featured_offers_opened'][i].to_f
        end
      end
    end
    
    # featured_fill_rate
    if @stats['featured_offers_requested'] and @stats['featured_offers_shown']
      @stats['featured_fill_rate'] = []
      @stats['featured_offers_requested'].length.times do |i|
        if @stats['featured_offers_requested'][i] == 0
          @stats['featured_fill_rate'][i] = 0
        else
          @stats['featured_fill_rate'][i] = @stats['featured_offers_shown'][i].to_f / @stats['featured_offers_requested'][i].to_f
        end
      end
    end
    
    # featured_ecpm
    if @stats['featured_offers_shown'] and @stats['featured_revenue']
      @stats['featured_ecpm'] = []
      @stats['featured_offers_shown'].length.times do |i|
        if @stats['featured_offers_shown'][i] == 0
          @stats['featured_ecpm'][i] = 0
        else
          @stats['featured_ecpm'][i] = @stats['featured_revenue'][i].to_f / (@stats['featured_offers_shown'][i] / 1000.0)
        end
      end
    end
    
    # display_fill_rate
    if @stats['display_ads_requested'] and @stats['display_ads_shown']
      @stats['display_fill_rate'] = []
      @stats['display_ads_requested'].length.times do |i|
        if @stats['display_ads_requested'][i] == 0
          @stats['display_fill_rate'][i] = 0
        else
          @stats['display_fill_rate'][i] = @stats['display_ads_shown'][i].to_f / @stats['display_ads_requested'][i].to_f
        end
      end
    end
    
    # display_ctr
    if @stats['display_ads_shown'] and @stats['display_clicks']
      @stats['display_ctr'] = []
      @stats['display_ads_shown'].length.times do |i|
        if @stats['display_ads_shown'][i] == 0
          @stats['display_ctr'][i] = 0
        else
          @stats['display_ctr'][i] = @stats['display_clicks'][i].to_f / @stats['display_ads_shown'][i].to_f
        end
      end
    end
    
    # display_cvr
    if @stats['display_clicks'] and @stats['display_conversions']
      @stats['display_cvr'] = []
      @stats['display_clicks'].length.times do |i|
        if @stats['display_clicks'][i] == 0
          @stats['display_cvr'][i] = 0
        else
          @stats['display_cvr'][i] = @stats['display_conversions'][i].to_f / @stats['display_clicks'][i].to_f
        end
      end
    end
    
    # display_ecpm
    if @stats['display_ads_shown'] and @stats['display_revenue']
      @stats['display_ecpm'] = []
      @stats['display_ads_shown'].length.times do |i|
        if @stats['display_ads_shown'][i] == 0
          @stats['display_ecpm'][i] = 0
        else
          @stats['display_ecpm'][i] = @stats['display_revenue'][i].to_f / (@stats['display_ads_shown'][i] / 1000.0)
        end
      end
    end
    
    # non_display_revenue
    if @stats['rewards_revenue'] and @stats['featured_revenue']
      @stats['non_display_revenue'] = []
      @stats['rewards_revenue'].length.times do |i|
        @stats['non_display_revenue'][i] = @stats['rewards_revenue'][i] + @stats['featured_revenue'][i]
      end
    end

    # total_revenue
    if @stats['rewards_revenue'] and @stats['featured_revenue'] and @stats['display_revenue']
      @stats['total_revenue'] = []
      @stats['rewards_revenue'].length.times do |i|
        @stats['total_revenue'][i] = @stats['rewards_revenue'][i] + @stats['featured_revenue'][i] + @stats['display_revenue'][i]
      end
    end

    # arpdau
    if @granularity == :daily and @stats['daily_active_users'] and @stats['total_revenue']
      @stats['arpdau'] = []
      @stats['daily_active_users'].length.times do |i|
        if @stats['daily_active_users'][i] == 0
          @stats['arpdau'][i] = 0
        else
          @stats['arpdau'][i] = @stats['total_revenue'][i].to_f / @stats['daily_active_users'][i]
        end
      end
    end
    
    get_labels_and_intervals(@start_time, @end_time) if @include_labels
  end
  
private

  ##
  # Returns the hourly stats for stat_name.
  # If stat_name corresponds to a single stat, then the returned object will be an array with each
  # value representing a single hour's worth of stats.
  # If stat_name corresponds to a set of stats (e.g. 'ranks'), then the returned object will be a 
  # hash, with the values of the hash being arrays of hourly stats.
  def get_hourly_stats(stat_name, start_time, end_time, cache_hours)
    time = start_time
    date = nil
    hourly_stats_over_range = []
    hourly_stats = []
    size = ((end_time - start_time) / 1.hour).ceil
    index = 0
    while time < end_time
      if date != time.strftime('%Y-%m-%d')
        date = time.strftime('%Y-%m-%d')
        stat = load_stat_row("app.#{date}.#{@app_key}")
        populate_hourly_stats_from_memcached(stat, stat_name, cache_hours)
        hourly_stats = stat.get_hourly_count(stat_name)
      end
      
      if hourly_stats.is_a?(Hash)
        hourly_stats_over_range = {} if hourly_stats_over_range.blank?
        hourly_stats.each do |key, values|
          value = values[time.hour]
          unless value == 0
            hourly_stats_over_range[key] ||= Array.new(size, 0)
            hourly_stats_over_range[key][index] = value
          end
        end
      else
        hourly_stats_over_range[index] = hourly_stats[time.hour]
      end
      
      time = time + 1.hour
      index += 1
    end
    return hourly_stats_over_range
  end

  ##
  # Returns the daily stats for stat_name, an array or a hash. See #get_hourly_stats.
  def get_daily_stats(stat_name, start_time, end_time, cache_hours)
    time = start_time
    daily_stats_over_range = []
    daily_stats = []
    date = nil
    size = ((end_time - start_time) / 1.day).ceil
    index = 0
    while time + 1.hour < end_time
      if date != time.strftime('%Y-%m')
        date = time.strftime('%Y-%m')
        stat = load_stat_row("app.#{date}.#{@app_key}")
        daily_stats = stat.get_daily_count(stat_name)
      end
      
      if time + 28.hours > @now
        hourly_stat = load_stat_row("app.#{date}-#{time.strftime("%d")}.#{@app_key}")
        populate_hourly_stats_from_memcached(hourly_stat, stat_name, cache_hours)
        stat.populate_daily_from_hourly(hourly_stat, time.day - 1)
        daily_stats = stat.get_daily_count(stat_name)
      end

      if daily_stats.is_a?(Hash)
        daily_stats_over_range = {} if daily_stats_over_range.blank?
        daily_stats.each do |key, values|
          value = values[time.day - 1]
          unless value[time.day - 1] == 0
            daily_stats_over_range[key] ||= Array.new(size, 0)
            daily_stats_over_range[key][index] = value
          end
        end
      else
        daily_stats_over_range[index] = daily_stats[time.day - 1]
      end
      
      time = time + 1.day
      index += 1
    end
    return daily_stats_over_range
  end
  
  def load_stat_row(key)
    unless @stat_rows[key]
      @stat_rows[key] = Stats.new(:key => key)
    end
    @stat_rows[key]
  end
  
  def populate_hourly_stats_from_memcached(stat_row, stat_name, cache_hours)
    return if cache_hours == 0
    
    date, app_id = stat_row.parse_key
    if stat_name == 'virtual_goods'
      vg_keys = Mc.get("virtual_good_list.keys.#{app_id}") || []
      vg_keys.each do |vg_key|
        counts = stat_row.get_hourly_count(['virtual_goods', vg_key])
        24.times do |i|
          time = date + i.hours
          if counts[i] == 0 && time <= @now && time >= (@now - cache_hours.hours)
            counts[i] = Mc.get_count(Stats.get_memcache_count_key(['virtual_goods', vg_key], app_id, time))
          end
        end
      end
    elsif stat_name == 'country_conversions'
      Stats::TOP_COUNTRIES.each do |country|
        ['paid_installs', 'installs_spend', 'paid_clicks'].each do |stat|
          att = "#{stat}.#{country}"
          counts = stat_row.get_hourly_count([stat_name, att])
          24.times do |i|
            time = date + i.hours
            if counts[i] == 0 && time <= @now && time >= (@now - cache_hours.hours)
              counts[i] = Mc.get_count(Stats.get_memcache_count_key(stat, app_id, time, country))
            end
          end
        end
      end
    else
      counts = stat_row.get_hourly_count(stat_name)
      if counts.is_a?(Array)
        24.times do |i|
          time = date + i.hours
          if counts[i] == 0 && time <= @now && time >= (@now - cache_hours.hours)
            counts[i] = Mc.get_count(Stats.get_memcache_count_key(stat_name, app_id, time))
          end
        end
      end
    end
  end
  
  def get_labels_and_intervals(start_time, end_time)
    @intervals = []
    @x_labels = []
    
    while start_time < end_time
      @intervals << start_time
      
      if @granularity == :daily
        @x_labels << start_time.strftime('%m-%d')
      else
        @x_labels << start_time.to_s(:time)
      end
      
      start_time += (@granularity == :daily ? 1.day : 1.hour)
    end
    
    if @x_labels.size > 30
      skip_every = @x_labels.size / 30
      @x_labels.size.times do |i|
        if i % (skip_every + 1) != 0
          @x_labels[i] = nil
        end
      end
    end
    
    @intervals << start_time
  end
  
end
