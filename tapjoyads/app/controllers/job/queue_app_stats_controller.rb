class Job::QueueAppStatsController < Job::SqsReaderController
  include NewRelicHelper
  include DownloadContent
  
  def initialize
    super QueueNames::APP_STATS
    @paths_to_aggregate = %w(connect new_user adshown store_click store_install daily_user monthly_user purchased_vg)
    @publisher_paths_to_aggregate = %w(store_click store_install)
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    
    @app = SdbApp.new(:key => json['app_key'])
    @now = Time.zone.now
    @stat_rows = {}
    
    start_time = Time.zone.at(json['last_run_time'].to_f).beginning_of_hour
    end_time = (@now - 5.minutes).beginning_of_hour
    
    Rails.logger.info "Aggregating stats for '#{@app.to_s}' from #{start_time} to #{end_time}"
    
    while start_time < end_time do
      count_stats_for_hour(start_time)
      start_time += 1.hour
    end
    
    @stat_rows.each_value do |row|
      row.save
    end
    
    @app.next_run_time = @now + get_interval
    @app.last_run_time = end_time
    verify_yesterday
    @app.save
    
    start_time = Time.at(json['last_run_time'].to_f).beginning_of_hour
    start_time.to_date.upto(@now.to_date) do |date|
      send_stats_to_mssql(date)
    end
  end
  
  def count_stats_for_hour(start_time)
    end_time = start_time + 1.hour
    date_string = start_time.to_date.to_s(:db)
    stat_row = @stat_rows[date_string] || Stats.new(:key => "app.#{date_string}.#{@app.key}")
    @stat_rows[date_string] = stat_row
    
    Rails.logger.info "Counting hour from #{start_time} to #{end_time}"
    
    time_condition = "time >= '#{start_time.to_f.to_s}' and time < '#{end_time.to_f.to_s}'"
    
    @paths_to_aggregate.each do |path|
      stat_name = WebRequest::PATH_TO_STAT_MAP[path]
      app_condition = WebRequest::USE_ADVERTISER_APP_ID.include?(path) ? "advertiser_app_id = '#{@app.key}'" : "app_id = '#{@app.key}'"
      
      count = WebRequest.count(:date => date_string,
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      
      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
    
    @publisher_paths_to_aggregate.each do |path|
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[path]
      app_condition = "publisher_app_id = '#{@app.key}'"
      
      count = WebRequest.count(:date => date_string,
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")

      stat_row.update_stat_for_hour(stat_name, start_time.hour, count)
    end
  end
  
  ##
  #
  def verify_yesterday
    return unless @app.last_daily_run_time.nil? || @app.last_daily_run_time.day != @now.day
    
    start_time = (@now - 1.day).beginning_of_day
    end_time = start_time + 1.day
    date_string = start_time.to_date.to_s(:db)
    stat_row = @stat_rows[date_string] || Stats.new(:key => "app.#{date_string}.#{@app.key}")
    @stat_rows[date_string] = stat_row
    
    Rails.logger.info "Verifying stats for #{@app.to_s} for #{date_string}"
    
    time_condition = "time >= '#{start_time.to_f.to_s}' and time < '#{end_time.to_f.to_s}'"
    
    @paths_to_aggregate.each do |path|
      stat_name = WebRequest::PATH_TO_STAT_MAP[path]
      app_condition = WebRequest::USE_ADVERTISER_APP_ID.include?(path) ? "advertiser_app_id = '#{@app.key}'" : "app_id = '#{@app.key}'"
      
      count = WebRequest.count(:date => date_string, 
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      hour_counts = stat_row.get_hourly_count(stat_name, 0)
      
      if count != hour_counts.sum
        raise AppStatsVerifyError.new("#{stat_name}: 24 hour count was: #{count}, hourly counts were: #{hour_counts.join(', ')}.")
      end
      Rails.logger.info "#{stat_name} verified, both counts are: #{count}."
    end
    
    @publisher_paths_to_aggregate.each do |path|
      stat_name = WebRequest::PUBLISHER_PATH_TO_STAT_MAP[path]
      app_condition = "publisher_app_id = '#{@app.key}'"
      
      count = WebRequest.count(:date => date_string, 
          :where => "#{time_condition} and path = '#{path}' and #{app_condition}")
      hour_counts = stat_row.get_hourly_count(stat_name, 0)
      
      if count != hour_counts.sum
        raise AppStatsVerifyError.new("#{stat_name}: 24 hour count was: #{count}, hourly counts were: #{hour_counts.join(', ')}.")
      end
      Rails.logger.info "#{stat_name} verified, both counts are: #{count}."
    end
    
    @app.last_daily_run_time = @now
  rescue AppStatsVerifyError => e
    @app.last_run_time = start_time
    @app.next_run_time = @now
    
    msg = "Verification of stats failed for app: #{@app.to_s}, for date: #{start_time.to_date}. #{e.message}"
    Rails.logger.info msg
    alert_new_relic(AppStatsVerifyError, msg, request, params)
  end
  
  def send_stats_to_mssql(utc_date)
    key = @app.key
    offset = -6 # CST timezone. Must be negative the way this is currently implemented.
    
    today = utc_date.to_s(:db)
    tomorrow = (utc_date + 1.days).to_s(:db)
    
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
      'installs_spend' => 'MoneySpentOnInstalls',
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

    download_with_retry(url, {:timeout => 30})
  end
  
  ##
  # Gets the updates interval for this app, based on the contents of stat_row. 
  def get_interval
    stat_row = @stat_rows.values[0]
    if @now.hour <= 4
      # Never calculate the interval during the first 4 hours of a day.
      # This is because it's possible that stats haven't been tallied yet.
      # Just use the previously set interval.
      app_update_time = @app.get('interval_update_time') || 1.hour
      return [app_update_time.to_i, 1.hour].max
    end
    
    total_logins = stat_row.get_hourly_count('logins').sum
    total_rewards = stat_row.get_hourly_count('rewards').sum
    total_paid_clicks = stat_row.get_hourly_count('paid_clicks').sum
    total_ad_impressions = stat_row.get_hourly_count('hourly_impressions').sum
    
    if total_logins + total_rewards + total_paid_clicks + total_ad_impressions > 0
      new_interval = 1.hour
    else
      new_interval = 8.hour
    end
    
    @app.put('interval_update_time', new_interval)
    
    new_interval
  end
end