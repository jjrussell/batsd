class Job::MasterDailyAppStatsController < Job::JobController
  
  def index
    next_aggregation_time = Time.zone.now + 1.day
    offer_ids = Offer.to_aggregate_daily_stats.collect(&:id)
    
    Offer.connection.execute("UPDATE offers SET next_daily_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
    
    offer_ids.each do |offer_id|
      Sqs.send_message(QueueNames::APP_STATS_DAILY, offer_id)
    end
    
    render :text => 'ok'
  end
  
end
