class CampaignStatsJob
  include StatsProcessorHelper
  
  def run
    now = Time.now.utc
    
    campaign_id = get_item_to_process('campaign', 'next_run_time', now)
    
    unless campaign_id
      Rails.logger.info "No campaign stats to process"
      return
    end
    Rails.logger.info("Processing campaign stats: #{campaign_id}")
    
    item_type = 'campaign'
    
    campaign = Campaign.new(campaign_id)
    stat = Stats.new(get_stat_key(item_type, campaign_id, now))
    
    last_hour = get_last_run_hour_in_day(campaign.get('last_run_time'), now)
    
    hourly_impressions = get_hourly_impressions(last_hour, now.hour, now, item_type, campaign_id, 
        stat.get('hourly_impressions'))
    
    stat.put('hourly_impressions', hourly_impressions.join(','))
    stat.save
    
    interval = stat.get('interval_update_time') || 60
    new_next_run_time = now + interval
    campaign.put('next_run_time', new_next_run_time.to_f.to_s)
    campaign.put('last_run_time', now.to_f.to_s)
    campaign.save
  end
end