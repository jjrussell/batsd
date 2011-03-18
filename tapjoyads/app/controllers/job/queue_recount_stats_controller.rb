class Job::QueueRecountStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::RECOUNT_STATS
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    start_time = Time.zone.at(json['start_time'])
    end_time = Time.zone.at(json['end_time'])
    
    StatsAggregation.recount_stats_over_range(json['offer_id'], start_time, end_time)
  end
  
end
