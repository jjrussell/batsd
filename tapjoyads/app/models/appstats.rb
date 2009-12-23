class Appstats
  
  attr_accessor :app_key, :stats, :granularity, :start_time, :end_time
  
  def initialize(app_key, options = {})
    @app_key = app_key
    
    now = Time.now.utc
    @granularity = options.delete(:granularity) { :hourly }
    @start_time = options.delete(:start_time) { Time.utc(now.year, now.month, now.day) }
    @end_time = options.delete(:end_time) { now }
    @stat_types = options.delete(:stat_types) { ['logins', 'hourly_impressions', 'paid_installs', 
        'installs_spend', 'paid_clicks'] }
    @type = options.delete(:type) { :granular }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
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
  end
  
  def get_hourly_stats_over_range(stat_type, start_time, end_time)
    time = start_time
    date = nil
    hourly_stats_over_range = []
    hourly_stats = []
    while time < end_time
      if date != time.iso8601[0,10]
        date = time.iso8601[0,10]
        stat = Stats.new("app.#{date}.#{@app_key}")
        hourly_stats = stat.get_hourly_count(stat_type)
      end
      hourly_stats_over_range.push(hourly_stats[time.hour])
      time = time + 1.hour
    end
    return hourly_stats_over_range
  end

  def get_daily_stats_over_range(stat_type, start_time, end_time)
    # TODO: Get this stats from a stats_daily domain
    time = start_time
    daily_stats_over_range = []
    while time < end_time
      date = time.iso8601[0,10]
      stat = Stats.new("app.#{date}.#{@app_key}")
      puts stat.get_hourly_count(stat_type).to_json + date
      daily_stats_over_range.push(stat.get_hourly_count(stat_type).sum)
      time = time + 1.day
    end
    return daily_stats_over_range
  end
end