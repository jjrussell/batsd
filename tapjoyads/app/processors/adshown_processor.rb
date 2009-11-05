class AdshownStatsProcessor < ApplicationProcessor

  subscribes_to :adshown_stats
  
  def message(campaign_id, app_id, udid, timestamp)
    time = Time.at(timestamp.to_f)
    date = time.iso8601[0,10]
    
    campaign_stats = Stats.new("campaign.#{date}.#{campaign_id}")
    campaign_stats.increment_count("impressions.h#{time.hour}")
    campaign_stats.save
    logger.info "Adshown campaign stats stored. Simpledb box usage: #{campaign_stats.box_usage}"
    
    app_stats = Stats.new("app.#{date}.#{app_id}")
    app_stats.increment_count("impressions.h#{time.hour}")
    app_stats.save
    logger.info "Adshown app stats stored. Simpledb box usage: #{campaign_stats.box_usage}"
  end
  
  def log(message)
    logger.debug "AdshownStatsProcessor received: " + message
  end
  
end