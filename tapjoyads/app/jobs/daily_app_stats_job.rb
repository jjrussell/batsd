class DailyAppStatsJob
  def run
    now = Time.now.utc
    
    response = SimpledbResource.query('app', 'next_daily_run_time', 
        "next_daily_run_time < '#{now.to_f.to_s}'", 'next_daily_run_time asc')
    if (response.items.length == 0)
      Rails.logger.info "No daily app stats to process"
      return
    end
    
    app = App.new(response.items[0].name)
    
    Rails.logger.info("Processing daily app stats:" + response.items[0].name + ' ' + response.items[0].attributes[0].value)
    
    item_type = 'app'
    item_id = app.item.key
    yesterday = now - 1.day
    date = yesterday.iso8601[0,10]
    
    #get the current stat row for this item
    key = "#{item_type}.#{date}.#{item_id}"
    
    stat = Stats.new(key)
    
    hourly_impressions = Array.new(24, 0)
    
    for hour in 0..23
      min_time = Time.utc(now.year, now.month, now.day, hour, 0, 0, 0)
      max_time = min_time + 1.hour
      count = SimpledbResource.count("web-request-#{date}", 
          "time >= '#{min_time.to_f.to_s}' and time < '#{max_time.to_f.to_s}' and #{item_type}_id = '#{item_id}'")
      hourly_impressions[hour] = count
    end
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    new_next_daily_run_time = now + 4.hour
    app.put('next_daily_run_time', new_next_daily_run_time.to_f.to_s)
    app.save
  end
end