class Job::QueueAppStatsController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::APP_STATS
    @now = Time.now.utc
    @date = @now.iso8601[0,10]
    @paths_to_aggregate = %w(connect new_user adshown)
  end
  
  private
  
  def on_message(message)
    puts message.to_s
    json = JSON.parse(message.to_s)
    app_key = json['app_key']
    last_run_time = json['last_run_time']
    
    app = App.new(app_key)
    
    first_hour = get_last_run_hour_in_day(last_run_time)
    last_hour = @now.hour - 1
    
    stat_row = Stats.new("app.#{@date}.#{app_key}")
    
    @paths_to_aggregate.each do |path|
      aggregate_stat(stat_row, path, app_key, first_hour, last_hour)
    end
    
    stat_row.save
    
    new_next_run_time = @now + get_interval(stat_row)
    app.put('next_run_time', new_next_run_time.to_f.to_s)
    
    # Set the last_run_time to 1 hour ago, since we only aggregated the stats up to that point.
    app.put('last_run_time', (@now - 1.hour).to_f.to_s)
    app.save
    
    aggregate_yesterday(app)
    
    send_stats_to_mssql(app.key, 'cst')
  end
  
  ##
  # Aggregate yesterday's complete stats - if it hasn't been done yet.
  def aggregate_yesterday(app)
    last_daily_run_time = app.get('last_daily_run_time')
    if last_daily_run_time
      if Time.at(last_daily_run_time.to_f).day == @now.day or @now.hour == 0
        return
      end
    end
    
    time = @now - 1.day
    date = time.iso8601[0,10]
    stat_row = Stats.new("app.#{date}.#{app.key}")
    
    @paths_to_aggregate.each do |path|
      aggregate_stat(stat_row, path, app.key, 0, 23, time)
    end
    
    app.put('last_daily_run_time', Time.now.utc.to_f.to_s)
    app.save
    
    # TODO: put daily stats in daily_stats domain.
  end
  
  def send_stats_to_mssql(key, time_zone)
    item = key
    time = Time.now.utc + Time.zone_offset(time_zone)
    day = time.iso8601[0,10]
    yesterday = (time - 1.days).iso8601[0,10]
    
    stat_today = Stats.new("app.#{day}.#{key}")
    stat_yesterday = Stats.new("app.#{yesterday}.#{key}")
    
    cst_hour = time.hour
    utc_hour = Time.now.utc.hour 
    
    map = {
      'new_users' => 'NewUsers',
      'logins' => 'GameSessions',
      'paid_installs' => 'RewardedInstalls',
      'paid_clicks' => 'RewardedInstallClicks',
      'rewards' => 'CompletedOffers',
      'rewards_revenue' => 'OfferRevenue',
      'rewards_opened' => 'OffersOpened'
    }
    
    start_hour = utc_hour - cst_hour
    length = cst_hour + 1
    
    stats = {}
    map.each do |type, val|
      yesterday_sum = 0
      today_start_hour = start_hour
      if start_hour < 0
        yesterday_sum = stat_yesterday.get_hourly_count(type)[24 + start_hour, 
          0 - start_hour].sum
        today_start_hour = 0
        length = cst_hour
      end
      today_sum = stat_today.get_hourly_count(type)[today_start_hour,length].sum
      stats[val] = today_sum + yesterday_sum
    end
    
    stats['RewardedInstallConversionRate'] = (stats['RewardedInstalls'] * 10000 / stats['RewardedInstallClicks']).to_i if stats['RewardedInstallClicks'].to_i > 0
    stats['OfferCompletionRate'] = (stats['CompletedOffers'] * 10000 / stats['OffersOpened']).to_i if stats['OffersOpened'].to_i > 0
    
    stat_types = ''
    datas = ''
    
    stats.each do |s, d|
      stat_types += ',' unless stat_types == ''
      stat_types += s
      datas += ',' unless datas == ''
      datas += d.to_s
    end
    
    send_stats_to_windows(day, stat_types, key, datas)
  end
  
  def send_stats_to_windows(date, stat_types, item_id, datas)
    url = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/CronService.asmx/SubmitMultipleStats?'
    url += "Date=#{CGI::escape(date)}"
    url += "&StatTypes=#{CGI::escape(stat_types)}"
    url += "&item=#{item_id}"
    url += "&Datas=#{CGI::escape(datas)}"
    
    download_content(url, {:timeout => 30, :internal_authenticate => true})
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
    return 2.hour
    
    #TODO: calculate interval based on number of logins.

    # logins_string = stat_row.get('connect') || ''
    # logins = logins_string.split(',').map{|num| num.to_i }.sum
  end
end