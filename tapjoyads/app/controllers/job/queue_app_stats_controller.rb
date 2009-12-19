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
    
    send_stats_to_mssql(app.key, 'cst')
    
  end
  
  def send_stats_to_mssql(key, time_zone)
    
    item = key
    time = Time.now.utc + Time.zone_offset(time_zone)
    day = time.iso8601[0,10]
    yesterday = (time - 1.days).iso8601[0,10]
    
    stat_today = Stats.new("app.#{day}.#{key}")
    stat_yesterday = Stats.new("app.#{yesterday}.#{key}")
    
    current_hour = Time.now.utc.hour + 1
    
    map = {
      'new_users' => 'NewUsers',
      'logins' => 'GameSessions',
      'paid_installs' => 'RewardedInstalls',
      'paid_clicks' => 'RewardedInstallClicks',
      'rewards' => 'CompletedOffers',
      'rewards_revenue' => 'OfferRevenue',
      'rewards_opened' => 'OffersOpened'
    }
    
    stats = {}
    map.each do |type, val|
      today_sum = stat_today.get_hourly_count(type).sum
      yesterday_sum = stat_yesterday.get_hourly_count(type)[current_hour, 24 - current_hour].sum
      stats[val] = today_sum + yesterday_sum
    end
    
    stats['RewardedInstallConversionRate'] = (stats['RewardedInstalls'] * 10000 / stats['RewardedInstallClicks']).to_i
    stats['OfferCompletionRate'] = (stats['CompletedOffers'] * 10000 / stats['OffersOpened']).to_i
    
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
    url += "&Data=#{CGI::escape(datas)}"
    
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
    return 1.hour
    
    #TODO: calculate interval based on number of logins.

    # logins_string = stat_row.get('connect') || ''
    # logins = logins_string.split(',').map{|num| num.to_i }.sum
  end
end