class FixAppNilsJob
  def run
    response = SimpledbResource.query('app', 'next_run_time, interval_update_time, next_daily_run_time', 
      "next_run_time is null or interval_update_time is null", '')
      
    response.items.each do |item| 
      app_id = item.name
      app = App.new(app_id)
      
      unless (item.attributes[0])
        next_run_time = (Time.now.utc + 1.minutes).to_f.to_s
        app.put('next_run_time', next_run_time)     
        Rails.logger.info("Added next_run_time to #{app_id} for #{next_run_time}")
      end
      
      unless (item.attributes[1])
        app.put('interval_update_time','60')
        Rails.logger.info("Added interval time to #{app_id} for 60 seconds")
      end
      
      unless (item.attributes[2])
        next_run_time = (Time.now.utc + 4.hours).to_f.to_s
        app.put('next_daily_run_time', next_run_time)
        Rails.logger.info("Added next_daily_run_time to #{app_id} for #{next_run_time}")
      end
      
      app.save

    end
  end
end