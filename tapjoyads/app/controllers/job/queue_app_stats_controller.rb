class Job::QueueAppStatsController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::APP_STATS
    @now = Time.now.utc
    @date = @now.iso8601[0,10]
  end
  
  private
  
  def on_message(message)
    puts message.to_s
    json = JSON.parse(message.to_s)
    app_key = json['app_key']
    
    app = App.new(app_key)
    
    first_hour = get_last_run_hour_in_day(app.get('last_run_time'))
    last_hour = @now.hour - 1
    
    stat_row = Stats.new("app.#{@date}.#{app_key}")
    
    aggregate_stat(stat_row, 'connect', app_key, first_hour, last_hour)
    aggregate_stat(stat_row, 'new_user', app_key, first_hour, last_hour)
    aggregate_stat(stat_row, 'adshown', app_key, first_hour, last_hour)
    
    stat_row.save
    
    new_next_run_time = @now + get_interval(stat_row)
    app.put('next_run_time', new_next_run_time.to_f.to_s)
    app.put('last_run_time', @now.to_f.to_s)
    app.save
  end
  
  def aggregate_stat(stat_row, wr_path, app_key, first_hour, last_hour, time = @now)
    stat_name = WebRequest::PATH_TO_STAT_MAP[wr_path]
    date = time.iso8601[0,10]
    
    hourly_stats_string = stat_row.get(stat_name)
    if hourly_stats_string
      hourly_stats = hourly_stats_string.split(',').map{|num| num.to_i }
    else
      hourly_stats = Array.new(24, 0)
    end
    
    for hour in first_hour..last_hour
      min_time = Time.utc(time.year, time.month, time.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      
      count = 0
      MAX_WEB_REQUEST_DOMAINS.times do |i|
        count += SimpledbResource.count("web-request-#{date}-#{i}", 
          "time >= '#{min_time.to_f.to_s}' and time < '#{max_time.to_f.to_s}' " +
          "and app_id = '#{app_key}' and path= '#{wr_path}'")
      end
      hourly_stats[hour] = count
    end
    
    stat_row.put(stat_name, hourly_stats.join(','))
    return hourly_stats
  end
  
  def get_last_run_hour_in_day(last_run_epoch)
    last_hour = 0
    if (last_run_epoch)
      last_run_time = Time.at(last_run_epoch.to_f)
      if last_run_time.day == @now.day
        last_hour = last_run_time.hour
      end
    end
    return last_hour
  end
  
  def get_interval(stat_row)
    return 1.hour
    
    #TODO: calculate interval based on number of logins.

    # logins_string = stat_row.get('connect') || ''
    # logins = logins_string.split(',').map{|num| num.to_i }.sum
  end
end