module StatsJobHelper
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
    stat = Stats.new(get_stat_key(domain_name, item_id, now))
    
    last_hour = get_last_run_hour_in_day(item.get('last_run_time'), now)
    
    hourly_impressions = get_hourly_impressions(last_hour, now.hour, now, domain_name, item_id, 
        stat.get('hourly_impressions'))
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    interval = item.get('interval_update_time') || 60
    new_next_run_time = now + interval
    item.put('next_run_time', new_next_run_time.to_f.to_s)
    item.put('last_run_time', now.to_f.to_s)
    item.save
  end
  
  def daily_stats(domain_name, domain_class)
    now = Time.now.utc
    
    item_id = get_item_to_process(domain_name, 'next_daily_run_time', now)
    
    unless item_id
      Rails.logger.info "No daily #{domain_name} stats to process"
      return
    end
    Rails.logger.info("Processing daily #{domain_name} stats: #{item_id}")
    
    item = domain_class.new(item_id)
    stat = Stats.new(get_stat_key(domain_name, item_id, now - 1.day))
    
    hourly_impressions = get_hourly_impressions(0, 23, now - 1.day, item_type, item_id, 
        stat.get('hourly_impressions'))
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    new_next_daily_run_time = now + 4.hour
    item.put('next_daily_run_time', new_next_daily_run_time.to_f.to_s)
    item.save
  end
  
  def get_item_to_process(domain_name, item_name, time)
    response = SimpledbResource.query(domain_name, item_name, 
        "#{item_name} < '#{time.to_f.to_s}'", "#{item_name} asc")
        
    if (response.items.length == 0)
      return nil
    end
    
    return response.items[0].name
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
      hourly_impressions_string)
    if hourly_impressions_string
      hourly_impressions = hourly_impressions_string.split(',')
    else
      hourly_impressions = Array.new(24, 0)
    end
    
    date = time.iso8601[0,10]
    
    for hour in last_hour..current_hour
      min_time = Time.utc(time.year, time.month, time.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      count = SimpledbResource.count("web-request-#{date}", 
          "time >= '#{min_time.to_f.to_s}' and time < '#{max_time.to_f.to_s}' and #{item_type}_id = '#{item_id}'")
      hourly_impressions[hour] = count
    end
    return hourly_impressions
  end
end