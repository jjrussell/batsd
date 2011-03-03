class Job::MasterHourlyAppStatsController < Job::JobController
  
  def index
    now = Time.zone.now
    
    Offer.to_aggregate_hourly_stats.find_each do |offer|
      offer.next_stats_aggregation_time = now + 1.hour
      offer.save(false)
      Sqs.send_message(QueueNames::APP_STATS_HOURLY, offer.id)
    end
    
    render :text => 'ok'
  end
  
end
