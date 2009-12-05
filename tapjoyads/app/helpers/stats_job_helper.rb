module StatsJobHelper
  include DownloadContent
  
  ##
  # Updates the hourly stats for a given domain.
  def hourly_stats(domain_name, domain_class)
    now = Time.now.utc
    
    item_id = get_item_to_process(domain_name, 'next_run_time', now)
    
    unless item_id
      Rails.logger.info "No #{domain_name} stats to process"
      return
    end
    Rails.logger.info("Processing #{domain_name} stats: #{item_id}")
    
    item = domain_class.new(item_id)
    last_hour = get_last_run_hour_in_day(item.get('last_run_time'), now)
    
    get_stats_over_range(domain_name, domain_class, item, item_id, last_hour, now.hour, now)
    
    interval = item.get('interval_update_time') || 60
    new_next_run_time = now + interval.to_f
    item.put('next_run_time', new_next_run_time.to_f.to_s)
    item.put('last_run_time', now.to_f.to_s)
    item.save
    
  end
  
  def get_stats_over_range(domain_name, domain_class, item, item_id, start_hour, end_hour, time)
    
    stat = Stats.new(get_stat_key(domain_name, item_id, time))
    
    hourly_impressions = get_hourly_impressions(start_hour, end_hour, time, domain_name, item_id, 
        stat.get('hourly_impressions'), 'adshown')
    
    send_stat_to_windows(time.iso8601[0,10], 'AdImpressions', item_id, hourly_impressions.sum)
    send_stat_to_windows(time.iso8601[0,10], 'AdRequests', item_id, hourly_impressions.sum)
    send_stat_to_windows(time.iso8601[0,10], 'FillRate', item_id, 10000)
        
    stat.put('hourly_impressions', hourly_impressions.join(','))
    
    if domain_name == 'app'
    
      hourly_impressions = get_hourly_impressions(start_hour, end_hour, time, domain_name, item_id, 
          stat.get('logins'), 'connect')
    
      send_stat_to_windows(time.iso8601[0,10], 'GameSessions', item_id, hourly_impressions.sum)
    
      stat.put('logins', hourly_impressions.join(','))
        
      paid_clicks = get_hourly_store_clicks(start_hour, end_hour, time, item_id, 
          stat.get('paid_clicks_to_store'), false, true)
    
      send_stat_to_windows(time.iso8601[0,10], 'RewardedInstallClicks', item_id, paid_clicks.sum)
          
      stat.put('paid_clicks_to_store', paid_clicks.join(','))
 
      paid_installs = get_hourly_store_clicks(start_hour, end_hour, time, item_id, 
          stat.get('paid_installs'), true, true)
    
      send_stat_to_windows(time.iso8601[0,10], 'RewardedInstalls', item_id, paid_installs.sum)
          
      stat.put('paid_installs', paid_installs.join(','))
      
      offer_clicks = get_hourly_offer_clicks(start_hour, end_hour, time, item_id, 
          stat.get('offer_clicks'))
    
      send_stat_to_windows(time.iso8601[0,10], 'OfferClicks', item_id, paid_clicks.sum)
          
      stat.put('offer_clicks', offer_clicks.join(','))
 
      paid_cvr = Array.new(24, 0)
      for i in (0..23)
        paid_cvr[i] = (paid_installs[i] / paid_clicks[i] * 10000.0).to_i if paid_clicks[i] > 0
      end
      
      stat.put('paid_install_cvr', paid_cvr.join(','))
      
      daily_paid_cvr = 0
      daily_paid_cvr = (paid_installs.sum / paid_clicks.sum * 10000.0).to_i if paid_clicks.sum > 0
      
      send_stat_to_windows(time.iso8601[0,10], 'RewardedInstallConversionRate', item_id, daily_paid_cvr)
      
      new_users = get_hourly_new_users(start_hour, end_hour, time, item_id,
        stat.get('new_users'))

      send_stat_to_windows(time.iso8601[0,10], 'NewUsers', item_id, new_users.sum)      
        
      stat.put('new_users', new_users.join(','))
      
             
    end
      
    stat.save
   
  end
  
  def yesterday_hourly_stats(domain_name, domain_class)
    
    now = Time.now.utc
    item_id = get_item_to_process(domain_name, 'next_daily_run_time', now)
    
    unless item_id
      Rails.logger.info "No yesterday's #{domain_name} stats to process"
      return
    end
    
    Rails.logger.info("Processing yesterday's #{domain_name} stats: #{item_id}")
    
    item = domain_class.new(item_id)
        
    get_stats_over_range(domain_name, domain_class, item, item_id, 0, 23, now - 1.day)
    
    new_next_daily_run_time = now + 4.hour
    item.put('next_daily_run_time', new_next_daily_run_time.to_f.to_s)
    item.save
    
  end
  
  def send_stat_to_windows(date, stat_type, item_id, data)
    
    url = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/CronService.asmx/SubmitStat?'
    url += "Date=#{CGI::escape(date)}"
    url += "&StatType=#{stat_type}"
    url += "&item=#{item_id}"
    url += "&Data=#{data}"
    
    download_content(url, {:timeout => 30, :internal_authenticate => true})

  end
  
  def get_item_to_process(domain_name, item_name, time)
    item_array = SimpledbResource.select(domain_name, item_name, 
        "#{item_name} < '#{time.to_f.to_s}'", "#{item_name} asc").items
        
    if (item_array.length == 0)
      return nil
    end
    
    # Choose a random item from the first 10 results.
    item_num = rand([10, item_array.length].min)
    return item_array[item_num].key
  end
  
  def get_stat_key(item_type, item_id, time)
    date = time.iso8601[0,10]
    return "#{item_type}.#{date}.#{item_id}"
  end
  
  def get_last_run_hour_in_day(last_run_epoch, now)
    last_hour = 0
    if (last_run_epoch)
      last_run_time = Time.at(last_run_epoch.to_f)
      if last_run_time.day == now.day
        last_hour = last_run_time.hour
      end
    end
    return last_hour
  end
  
  def get_hourly_new_users(last_hour, current_hour, time, item_id, 
      new_users_string)
    if new_users_string
      new_users = new_users_string.split(',')
      new_users.each_index do |i|
        new_users[i] = new_users[i].to_i
      end
    else
      new_users = Array.new(24, 0)
    end
    
    date = time.iso8601[0,10]
    
    for hour in last_hour..current_hour
      min_time = Time.utc(time.year, time.month, time.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      
      query = "`app.#{item_id}` >= '#{min_time.to_f.to_s}' and `app.#{item_id}` < '#{max_time.to_f.to_s}' "      

      count = SimpledbResource.count("device_app_list_1", query)
      new_users[hour] = count
    end
    return new_users
  end  

  def get_hourly_offer_clicks(last_hour, current_hour, time, item_id, 
      hourly_counts_string)
    if hourly_counts_string
      hourly_counts = hourly_counts_string.split(',')
      hourly_counts.each_index do |i|
        hourly_counts[i] = hourly_counts[i].to_i
      end
    else
      hourly_counts = Array.new(24, 0)
    end
    
    date = time.iso8601[0,10]
    
    for hour in last_hour..current_hour
      min_time = Time.utc(time.year, time.month, time.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      
      query = "click_date >= '#{min_time.to_f.to_s}' and click_date < '#{max_time.to_f.to_s}' "
      query += "and app_id = '#{item_id}' "
      
      count = SimpledbResource.count("offer-click", query)
      hourly_counts[hour] = count
    end
    
    return hourly_counts
  end
    
  def get_hourly_store_clicks(last_hour, current_hour, time, item_id, 
      hourly_counts_string, installed = false, advertiser = false)
    if hourly_counts_string
      hourly_counts = hourly_counts_string.split(',')
      hourly_counts.each_index do |i|
        hourly_counts[i] = hourly_counts[i].to_i
      end
    else
      hourly_counts = Array.new(24, 0)
    end
    
    date = time.iso8601[0,10]
    
    for hour in last_hour..current_hour
      min_time = Time.utc(time.year, time.month, time.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      
      query = "click_date >= '#{min_time.to_f.to_s}' and click_date < '#{max_time.to_f.to_s}' "
      if advertiser
        query += "and advertiser_app_id = '#{item_id}' "
      else
        query += "and publisher_app_id = '#{item_id}' "
      end
      
      query += "and installed != '' " if installed
      
      count = SimpledbResource.count("store-click", query)
      hourly_counts[hour] = count
    end
    return hourly_counts
  end
  
  def get_hourly_impressions(last_hour, current_hour, time, item_type, item_id, 
      hourly_impressions_string, path)
    if hourly_impressions_string
      hourly_impressions = hourly_impressions_string.split(',')
      hourly_impressions.each_index do |i|
        hourly_impressions[i] = hourly_impressions[i].to_i
      end
    else
      hourly_impressions = Array.new(24, 0)
    end
    
    date = time.iso8601[0,10]
    
    for hour in last_hour..current_hour
      min_time = Time.utc(time.year, time.month, time.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      count = 0
      for i in (0..MAX_WEB_REQUEST_DOMAINS - 1)
        count += SimpledbResource.count("web-request-#{date}-#{i}", 
          "time >= '#{min_time.to_f.to_s}' and time < '#{max_time.to_f.to_s}' " +
          "and #{item_type}_id = '#{item_id}' and path= '#{path}'")
      end
      hourly_impressions[hour] = count
    end
    return hourly_impressions
  end
end