class Appstats
  
  attr_accessor :app_key, :stats, :granularity, :start_time, :end_time, :x_labels, :intervals
  
  def initialize(app_key, options = {})
    @app_key = app_key
    
    @now = Time.zone.now
    @granularity = options.delete(:granularity) { :hourly }
    @start_time = options.delete(:start_time) { Time.utc(@now.year, @now.month, @now.day) }
    @end_time = options.delete(:end_time) { @now }
    @stat_types = options.delete(:stat_types) { Stats::STAT_TYPES }
    @type = options.delete(:type) { :granular }
    @include_labels = options.delete(:include_labels) { false }
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
    if @stats['installs_opened'] and @stats['offers_opened']
      @stats['rewards_opened'] = []
      @stats['installs_opened'].length.times do |i|
        @stats['rewards_opened'][i] = @stats['installs_opened'][i] + @stats['offers_opened'][i]
      end
    end
    
    # rewards_revenue
    if @stats['installs_revenue'] and @stats['offers_revenue']
      @stats['rewards_revenue'] = []
      @stats['installs_revenue'].length.times do |i|
        @stats['rewards_revenue'][i] = @stats['installs_revenue'][i] + @stats['offers_revenue'][i]
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
    
    # arpdau
    if @granularity == :daily and @stats['daily_active_users'] and @stats['rewards_revenue']
      @stats['arpdau'] = []
      @stats['daily_active_users'].length.times do |i|
        if @stats['daily_active_users'][i] == 0
          @stats['arpdau'][i] = 0
        else
          @stats['arpdau'][i] = @stats['rewards_revenue'][i].to_f / @stats['daily_active_users'][i]
        end
      end
    end
    
    get_labels_and_intervals(@start_time, @end_time) if @include_labels
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
