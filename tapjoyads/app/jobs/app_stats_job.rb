class AppStatsJob
  include StatsProcessorHelper
  
  def run
    now = Time.now.utc
    
    app_id = get_item_to_process('app', 'next_run_time', now)
    
    unless app_id
      Rails.logger.info "No app stats to process"
      return
    end
    Rails.logger.info("Processing app stats: #{app_id}")
    
    item_type = 'app'
    
    app = App.new(app_id)
    stat = Stats.new(get_stat_key(item_type, app_id, now))
    
    last_hour = get_last_run_hour_in_day(app.get('last_run_time'), now)
    
    hourly_impressions = get_hourly_impressions(last_hour, now.hour, now, item_type, app_id, 
        stat.get('hourly_impressions'))
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    interval = stat.get('interval_update_time') || 60
    new_next_run_time = now + interval
    app.put('next_run_time', new_next_run_time.to_f.to_s)
    app.put('last_run_time', now.to_f.to_s)
    app.save
  end
end