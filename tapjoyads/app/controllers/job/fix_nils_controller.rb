# Fills in default values for simpledb.

class Job::FixNilsController < Job::JobController
  
  def index
    fix_times('app', App)
    fix_times('campaign', Campaign)
    
    render :text => "ok"
  end
  
  private 
  
  def fix_times(domain, domain_class)
    items = SimpledbResource.select(domain, '*', 
      "next_run_time is null or interval_update_time is null or next_daily_run_time is null").items
      
    items.each do |item| 
      unless (item.get('next_run_time'))
        next_run_time = (Time.now.utc + 1.minutes).to_f.to_s
        item.put('next_run_time', next_run_time)     
        Rails.logger.info("Added next_run_time to #{item.key} for #{next_run_time}")
      end
      
      unless (item.get('interval_update_time'))
        item.put('interval_update_time','60')
        Rails.logger.info("Added interval time to #{item.key} for 60 seconds")
      end
      
      unless (item.get('next_daily_run_time'))
        next_run_time = (Time.now.utc + 4.hours).to_f.to_s
        item.put('next_daily_run_time', next_run_time)
        Rails.logger.info("Added next_daily_run_time to #{item.key} for #{next_run_time}")
      end
      
      item.save
    end
  end
end