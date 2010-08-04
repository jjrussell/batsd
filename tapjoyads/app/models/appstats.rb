class Appstats
  
  attr_accessor :app_key, :stats, :granularity, :start_time, :end_time
  
  def initialize(app_key, options = {})
    @app_key = app_key
    
    @now = Time.zone.now
    @granularity = options.delete(:granularity) { :hourly }
    @start_time = options.delete(:start_time) { Time.utc(@now.year, @now.month, @now.day) }
    @end_time = options.delete(:end_time) { @now }
    @stat_types = options.delete(:stat_types) { ['logins', 'hourly_impressions', 'paid_installs', 
        'installs_spend', 'paid_clicks', 'new_users', 'ratings', 'rewards', 'offers',
        'rewards_revenue', 'offers_revenue', 'installs_revenue', 'published_installs',
        'rewards_opened', 'offers_opened', 'installs_opened', 'daily_active_users', 
        'monthly_active_users', 'vg_purchases', 'overall_store_rank', 'offerwall_views'] }
    @type = options.delete(:type) { :granular }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    @stat_rows = {}
    
    @stats = {}
    @stat_types.each do |stat_type|
      if @type == :sum
        @stats[stat_type] = Array(get_daily_stats_over_range(stat_type, @start_time, @end_time).sum)
      elsif @granularity == :hourly
        @stats[stat_type] = get_hourly_stats_over_range(stat_type, @start_time, @end_time)
      elsif @granularity == :daily
        @stats[stat_type] = get_daily_stats_over_range(stat_type, @start_time, @end_time)
      else
        raise "Unsupported granularity"
      end
    end
    
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
  end
  
private

  ##
  # Returns an array of numbers, each representing a single hour's worth of stats.
  def get_hourly_stats_over_range(stat_type, start_time, end_time)
    time = start_time
    date = nil
    hourly_stats_over_range = []
    hourly_stats = []
    while time < end_time
      if date != time.iso8601[0,10]
        date = time.iso8601[0,10]
        stat = load_stat_row("app.#{date}.#{@app_key}")
        hourly_stats = stat.get_hourly_count(stat_type)
      end
      hourly_stats_over_range.push(hourly_stats[time.hour])
      time = time + 1.hour
    end
    return hourly_stats_over_range
  end

  ##
  # Returns an array of numbers, each representing a single day's worth of stats.
  def get_daily_stats_over_range(stat_type, start_time, end_time)
    time = start_time
    daily_stats_over_range = []
    date = nil
    while time < end_time
      if time + 28.hours > @now
        date = time.iso8601[0,10]
        stat = load_stat_row("app.#{date}.#{@app_key}")
        hourly_stats = stat.get_hourly_count(stat_type)
        
        if stat_type == 'overall_store_rank'
          daily_stats_over_range.push(stat.get_hourly_count(stat_type).reject{|r| r == '0' || r == '-'}.map{|i| i.to_i}.min || '-')
        else
          daily_stats_over_range.push(stat.get_hourly_count(stat_type).sum)
        end
      else
        if date != time.strftime('%Y-%m')
          date = time.strftime('%Y-%m')
          stat = load_stat_row("app.#{date}.#{@app_key}")
          daily_stats = stat.get_daily_count(stat_type)
        end
        
        daily_stats_over_range.push(daily_stats[time.day - 1])
      end
      time = time + 1.day
    end
    return daily_stats_over_range
  end
  
  def load_stat_row(key)
    unless @stat_rows[key]
      @stat_rows[key] = Stats.new(:key => key)
    end
    @stat_rows[key]
  end
end