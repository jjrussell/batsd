class DailyCampaignStatsJob
  include StatsProcessorHelper
  
  def run
    now = Time.now.utc
    
    campaign_id = get_item_to_process('campaign', 'next_daily_run_time', now)
    
    unless app_id
      Rails.logger.info "No daily campaign stats to process"
      return
    end
    Rails.logger.info("Processing daily campaign stats: #{campaign_id}")
    
    item_type = 'campaign'
    
    campaign = Campaign.new(app_id)
    stat = Stats.new(get_stat_key(item_type, app_id, now - 1.day))
    
    hourly_impressions = get_hourly_impressions(0, 23, now - 1.day, item_type, campaign_id, 
        stat.get('hourly_impressions'))
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    new_next_daily_run_time = now + 4.hour
    campaign.put('next_daily_run_time', new_next_daily_run_time.to_f.to_s)
    campaign.save
  end
end