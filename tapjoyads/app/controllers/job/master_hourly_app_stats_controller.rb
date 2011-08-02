class Job::MasterHourlyAppStatsController < Job::JobController
  
  def index
    next_aggregation_time = Time.zone.now + 1.hour
    offer_ids = Offer.to_aggregate_hourly_stats.collect(&:id)
    
    Offer.connection.execute("UPDATE offers SET next_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
    
    offer_ids.each do |offer_id|
      Sqs.send_message(QueueNames::APP_STATS_HOURLY, offer_id)
    end
    
    render :text => 'ok'
  end
  
end
