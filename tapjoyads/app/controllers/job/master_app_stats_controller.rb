class Job::MasterAppStatsController < Job::JobController
  def initialize
    @now = Time.zone.now
  end
  
  def index
    Offer.to_aggregate_stats.each do |offer|
      offer.update_attribute(:next_stats_aggregation_time, @now + 1.hour)
      Sqs.send_message(QueueNames::APP_STATS, offer.id)
    end
    
    render :text => 'ok'
  end
end