class AppStatsJob
  def run
    now = Time.now.utc
    current_time = now.to_f.to_s
    response = SimpledbResource.query('app', 'next_run_time', 
        "next_run_time < '#{current_time}'", 'next_run_time asc')
    if (response.items.length == 0)
      Rails.logger.info "No app stats to process"
      return
    end
    
    app = App.new(response.items[0].name)
    
    Rails.logger.info("Processing app stats:" + response.items[0].name + ' ' + response.items[0].attributes[0].value)
    
    item_type = 'app'
    item_id = app.item.key
    date = now.iso8601[0,10]
    
    #get the current stat row for this item
    key = "#{item_type}.#{date}.#{item_id}"
    
    stat = Stats.new(key)
    
    last_hour = 0
    if (app.get('last_run_time'))
      last_run_time = Time.at(app.get('last_run_time').to_f)
      if last_run_time.day == now.day
        last_hour = last_run_time.hour
      end
    end
    
    hourly_impressions_string = stat.get('hourly_impressions')
    if hourly_impressions_string
      hourly_impressions = hourly_impressions_string.split(',')
    else
      hourly_impressions = Array.new(24, 0)
    end
      
    for hour in last_hour..now.hour
      min_time = Time.utc(now.year, now.month, now.day, hour, 0, 0, 0).to_f.to_s
      max_time = Time.utc(now.year, now.month, now.day, hour + 1, 0, 0, 0).to_f.to_s
      count = SimpledbResource.count("web-request-#{date}", 
          "time >= '#{min_time}' and time < '#{max_time}' and #{item_type}_id = '#{item_id}'")
      hourly_impressions[hour] = count
    end
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    interval = stat.get('interval_update_time') || 60
    new_next_run_time = now + interval
    app.put('next_run_time', new_next_run_time.to_f.to_s)
    app.put('last_run_time', now.to_f.to_s)
    app.save
  end
end