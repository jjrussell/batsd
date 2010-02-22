class Job::QueueAppStatsController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::APP_STATS
    @now = Time.now.utc
    @date = @now.iso8601[0,10]
    @paths_to_aggregate = %w(connect new_user adshown store_click store_install daily_user monthly_user)
    @publisher_paths_to_aggregate = %w(store_click store_install)
  end
  
  private
  
  def on_message(message)
    puts message.to_s
    json = JSON.parse(message.to_s)
    app_key = json['app_key']
    last_run_time = json['last_run_time']
    
    app = App.new(:key => app_key)
    
    first_hour = get_last_run_hour_in_day(last_run_time)
    last_hour = @now.hour - 1
    
    stat_row = Stats.new(:key => "app.#{@date}.#{app_key}")
    
    @paths_to_aggregate.each do |path|
      aggregate_stat(stat_row, path, app_key, first_hour, last_hour)
    end
    @publisher_paths_to_aggregate.each do |path|
      aggregate_stat(stat_row, path, app_key, first_hour, last_hour, @now, true)
    end
    
    stat_row.save
    
    new_next_run_time = @now + get_interval(stat_row, app)
    app.put('next_run_time', new_next_run_time.to_f.to_s)
    
    # Set the last_run_time to 1 hour ago, since we only aggregated the stats up to that point.
    app.put('last_run_time', (@now - 1.hour).to_f.to_s)
    app.save
    
    aggregate_yesterday(app)
    
    send_stats_to_mssql(app.key, @now)
  end
  
  ##
  # Aggregate yesterday's complete stats - if it hasn't been done yet.
  def aggregate_yesterday(app)
    last_daily_run_time = app.get('last_daily_run_time')
    if last_daily_run_time
      if Time.at(last_daily_run_time.to_f).day == @now.day
        return
      end
      
      # Slowly ramp up running daily app stats.
      if rand(10) >= @now.hour
        return
      end
    end
    
    Rails.logger.info "Aggregating daily stats for #{app.key}"
    
    time = @now - 1.day
    date = time.iso8601[0,10]
    stat_row = Stats.new(:key => "app.#{date}.#{app.key}")
    
    @paths_to_aggregate.each do |path|
      aggregate_stat(stat_row, path, app.key, 0, 23, time)
    end
    @publisher_paths_to_aggregate.each do |path|
      aggregate_stat(stat_row, path, app.key, 0, 23, time, true)
    end
    
    stat_row.save
    
    app.put('last_daily_run_time', Time.now.utc.to_f.to_s)
    app.save
    
    send_stats_to_mssql(app.key, @now - 1.day)
    
    # TODO: put daily stats in daily_stats domain.
  end
  
  def send_stats_to_mssql(key, utc_date)
    offset = -6 # CST timezone. Must be negative the way this is currently implemented.
    
    today = utc_date.iso8601[0,10]
    tomorrow = (utc_date + 1.days).iso8601[0,10]
    
    stat_today = Stats.new(:key => "app.#{today}.#{key}")
    stat_tomorrow = Stats.new(:key => "app.#{tomorrow}.#{key}")
    
    stats = {}
    
    stats_map = {
      'new_users' => 'NewUsers',
      'logins' => 'GameSessions',
      'daily_active_users' => 'UniqueUsers',
      'paid_installs' => 'RewardedInstalls',
      'paid_clicks' => 'RewardedInstallClicks',
      'rewards' => 'CompletedOffers',
      'rewards_revenue' => 'OfferRevenue',
      'rewards_opened' => 'OffersOpened',
      'hourly_impressions' => 'AdImpressions'
    }
    
    stats_map.each do |sdb_type, sql_type|
      # Last 18 hours of utc-today, first 6 hours of utc-tomorrow.
      today_sum = stat_today.get_hourly_count(sdb_type)[-offset, 24].sum
      tomorrow_sum = stat_tomorrow.get_hourly_count(sdb_type)[0, -offset].sum
      stats[sql_type] = today_sum + tomorrow_sum
    end
    
    stats['RewardedInstallConversionRate'] = (stats['RewardedInstalls'] * 10000 / stats['RewardedInstallClicks']).to_i if stats['RewardedInstallClicks'].to_i > 0
    stats['OfferCompletionRate'] = (stats['CompletedOffers'] * 10000 / stats['OffersOpened']).to_i if stats['OffersOpened'].to_i > 0
    stats['FillRate'] = 10000
    stats['AdRequests'] = stats['AdImpressions']
    stat_types = ''
    datas = ''
    
    should_send = false
    stats.each do |s, d|
      stat_types += ',' unless stat_types == ''
      stat_types += s
      datas += ',' unless datas == ''
      datas += d.to_s
      
      if d != 0 and d != 10000
        should_send = true
      end
    end
    
    if should_send
      send_stats_to_windows(today, stat_types, key, datas)
    end
  end
  
  def send_stats_to_windows(date, stat_types, item_id, datas)
    # Amazon:
    url = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/CronService.asmx/SubmitMultipleStats?'
    # Mosso:
    #url = 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/CronService.asmx/SubmitMultipleStats?'
    
    url += "Date=#{CGI::escape(date)}"
    url += "&StatTypes=#{CGI::escape(stat_types)}"
    url += "&item=#{item_id}"
    url += "&Datas=#{CGI::escape(datas)}"
    
    download_with_retry(url, {:timeout => 30}, {:retries => 2})
  end
  
  def aggregate_stat(stat_row, wr_path, app_key, first_hour, last_hour, time = @now, is_publisher_stat = false)
    if is_publisher_stat
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[wr_path]
      app_condition = "publisher_app_id = '#{app_key}'"
    else
      stat_name = WebRequest::PATH_TO_STAT_MAP[wr_path]
      if WebRequest::USE_ADVERTISER_APP_ID.include?(wr_path)
        app_condition = "advertiser_app_id = '#{app_key}'"
      else
        app_condition = "app_id = '#{app_key}'"
      end
    end
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
        count += SimpledbResource.count({:domain_name => "web-request-#{date}-#{i}", 
            :where => "time >= '#{min_time.to_f.to_s}' and time < '#{max_time.to_f.to_s}' " +
            "and path = '#{wr_path}' and #{app_condition}"})
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
  
  ##
  # Gets the updates interval for this app, based on the contents of stat_row. 
  def get_interval(stat_row, app)
    if @now.hour <= 4
      # Never calculate the interval during the first 4 hours of a day.
      # This is because it's possible that stats haven't been tallied yet.
      # Just use the previously set interval.
      app_update_time = app.get('interval_update_time') || 1.hour
      return [app_update_time.to_i, 1.hour].max
    end
    
    total_logins = stat_row.get_hourly_count('logins').sum
    total_rewards = stat_row.get_hourly_count('rewards').sum
    total_paid_clicks = stat_row.get_hourly_count('paid_clicks').sum
    total_ad_impressions = stat_row.get_hourly_count('hourly_impressions').sum
    
    if total_logins + total_rewards + total_paid_clicks + total_ad_impressions > 0
      new_interval = 1.hour
    else
      new_interval = 4.hour
    end
    
    app.put('interval_update_time', new_interval.to_s)
    
    return new_interval
  end
end