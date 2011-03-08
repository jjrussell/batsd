class Job::MasterDailyAppStatsController < Job::JobController
  
  def index
    now = Time.zone.now
    
    Offer.to_aggregate_daily_stats.find_each do |offer|
      offer.next_daily_stats_aggregation_time = now + 1.day
      offer.save(false)
      Sqs.send_message(QueueNames::APP_STATS_DAILY, offer.id)
    end
    
    render :text => 'ok'
  end
  
end
