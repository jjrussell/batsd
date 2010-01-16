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
    
    item = domain_class.new(:key => item_id)
    last_hour = get_last_run_hour_in_day(item.get('last_run_time'), now)
    
    get_stats_over_range(domain_name, domain_class, item, item_id, last_hour, now.hour, now)
    
    interval = item.get('interval_update_time') || 60
    new_next_run_time = now + interval.to_f
    item.put('next_run_time', new_next_run_time.to_f.to_s)
    item.put('last_run_time', now.to_f.to_s)
    item.save
    
  end
  
  def get_stats_over_range(domain_name, domain_class, item, item_id, start_hour, end_hour, time)
    
    stat = Stats.new(:key => get_stat_key(domain_name, item_id, time))
    
    hourly_impressions = get_hourly_impressions(start_hour, end_hour, time, domain_name, item_id, 
        stat.get('hourly_impressions'), 'adshown')
    send_stat_to_windows(time.iso8601[0,10], 'AdImpressions', item_id, hourly_impressions.sum)
    send_stat_to_windows(time.iso8601[0,10], 'AdRequests', item_id, hourly_impressions.sum)
    send_stat_to_windows(time.iso8601[0,10], 'FillRate', item_id, 10000)
    stat.put('hourly_impressions', hourly_impressions.join(','))
    
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
    
    item = domain_class.new(:key => item_id)
        
    get_stats_over_range(domain_name, domain_class, item, item_id, 0, 23, now - 1.day)
    
    new_next_daily_run_time = now + 4.hour
    item.put('next_daily_run_time', new_next_daily_run_time.to_f.to_s)
    item.save
    
  end
  
  def send_stat_to_windows(date, stat_type, item_id, data)
    
    # Amazon:
    url = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/CronService.asmx/SubmitStat?'
    # Mosso:
    #url = 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/CronService.asmx/SubmitStat?'
    
    url += "Date=#{CGI::escape(date)}"
    url += "&StatType=#{stat_type}"
    url += "&item=#{item_id}"
    url += "&Data=#{data}"
    
    download_content(url, {:timeout => 30, :internal_authenticate => true})

  end
  
  def get_item_to_process(domain_name, item_name, time)
    item_array = SimpledbResource.select({
        :domain_name => domain_name, 
        :attributes => item_name, 
        :where => "#{item_name} < '#{time.to_f.to_s}'", 
        :order_by => "#{item_name} asc",
        :limit => '10'}).items
        
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
        count += SimpledbResource.count({:domain_name => "web-request-#{date}-#{i}", 
            :where => "time >= '#{min_time.to_f.to_s}' and time < '#{max_time.to_f.to_s}' " +
            "and #{item_type}_id = '#{item_id}' and path= '#{path}'"})
      end
      hourly_impressions[hour] = count
    end
    return hourly_impressions
  end
end