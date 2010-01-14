class Job::SendStatsController < Job::JobController
  include DownloadContent
  
  OFFSET = -6 # CST timezone. Must be negative the way this is currently implemented.
  
  def index
    date_string = (Time.now.utc + OFFSET.hours).iso8601[0,10]
    send_stats(date_string)
    
    render :text => 'ok'
  end
  
  def send_stats_for_date
    if params[:date]
      send_stats(params[:date])
      render :text => 'ok'
    else
      render :text => 'date param required'
    end
  end
  
  private 
  def send_stats(date_string)
    utc_date = Time.parse("#{date_string} 00:00 GMT").utc
    today = utc_date.iso8601[0,10]
    tomorrow = (utc_date + 1.days).iso8601[0,10]
    
    stats_map = {
      'new_users' => 'NewUsers',
      'logins' => 'GameSessions',
      'paid_installs' => 'RewardedInstalls',
      'paid_clicks' => 'RewardedInstallClicks',
      'rewards' => 'CompletedOffers',
      'rewards_revenue' => 'OfferRevenue',
      'rewards_opened' => 'OffersOpened',
      'hourly_impressions' => 'AdImpressions'
    }
    
    app_count = 0
    data_sent = 0
    
    App.select do |app|
      Rails.logger.info "#{app.get('name')} #{app.key}"
      
      stats = {}
      stat_today = Stats.new(:key => "app.#{today}.#{app.key}")
      stat_tomorrow = Stats.new(:key => "app.#{tomorrow}.#{app.key}")
      
      stats_map.each do |sdb_type, sql_type|
        # Last 18 hours of today, first 6 hours of tomorrow.
        today_sum = stat_today.get_hourly_count(sdb_type)[-OFFSET, 24].sum
        tomorrow_sum = stat_tomorrow.get_hourly_count(sdb_type)[0, -OFFSET].sum
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
        send_stats_to_windows(date_string, stat_types, app.key, datas) 
        data_sent += 1
      end
      app_count += 1
    end
    
    Rails.logger.info "Date: #{date_string}. Calculated stats for #{app_count} apps. Sent data for #{data_sent} apps."
  end
  
  def send_stats_to_windows(date, stat_types, item_id, datas)
    url = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/CronService.asmx/SubmitMultipleStats?'
    url += "Date=#{CGI::escape(date)}"
    url += "&StatTypes=#{CGI::escape(stat_types)}"
    url += "&item=#{item_id}"
    url += "&Datas=#{CGI::escape(datas)}"
    
    download_with_retry(url, {:timeout => 30}, {:retries => 2})
  end
  
end