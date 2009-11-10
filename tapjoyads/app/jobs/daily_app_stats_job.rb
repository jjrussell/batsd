class DailyAppStatsJob
  include StatsProcessorHelper
  
  def run
    now = Time.now.utc
    
    app_id = get_item_to_process('app', 'next_daily_run_time', now)
    
    unless app_id
      Rails.logger.info "No daily app stats to process"
      return
    end
    Rails.logger.info("Processing daily app stats: #{app_id}")
    
    item_type = 'app'
    
    app = App.new(app_id)
    stat = Stats.new(get_stat_key(item_type, app_id, now - 1.day))
    
    hourly_impressions = get_hourly_impressions(0, 23, now - 1.day, item_type, app_id, 
        stat.get('hourly_impressions'))
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    new_next_daily_run_time = now + 4.hour
    app.put('next_daily_run_time', new_next_daily_run_time.to_f.to_s)
    app.save
  end
end