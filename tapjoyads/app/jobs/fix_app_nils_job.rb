class FixAppNilsJob
  def run
    fix_times('app', App)
    fix_times('campaign', Campaign)
  end
  
  def fix_times(domain, domain_class)
    response = SimpledbResource.query(domain, 'next_run_time, interval_update_time, next_daily_run_time', 
      "next_run_time is null or interval_update_time is null or next_daily_run_time is null", '')
      
    response.items.each do |response_item| 
      item_id = response_item.name
      item = domain_class.new(item_id)
      
      unless (response_item.attributes[0])
        next_run_time = (Time.now.utc + 1.minutes).to_f.to_s
        item.put('next_run_time', next_run_time)     
        Rails.logger.info("Added next_run_time to #{item_id} for #{next_run_time}")
      end
      
      unless (response_item.attributes[1])
        item.put('interval_update_time','60')
        Rails.logger.info("Added interval time to #{item_id} for 60 seconds")
      end
      
      unless (response_item.attributes[2])
        next_run_time = (Time.now.utc + 4.hours).to_f.to_s
        item.put('next_daily_run_time', next_run_time)
        Rails.logger.info("Added next_daily_run_time to #{item_id} for #{next_run_time}")
      end
      
      item.save

    end
  end
  
end