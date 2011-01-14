class Job::MasterAppStatsController < Job::JobController
  def initialize
    @now = Time.zone.now
  end
  
  def index
    Offer.to_aggregate_stats.each do |offer|
      offer.next_stats_aggregation_time = @now + 1.hour + rand(600)
      offer.save(false)
      Sqs.send_message(QueueNames::APP_STATS, offer.id)
    end
    
    render :text => 'ok'
  end
end