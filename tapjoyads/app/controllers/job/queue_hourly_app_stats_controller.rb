class Job::QueueHourlyAppStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::APP_STATS_HOURLY
    @num_reads = 100
  end
  
private
  
  def on_message(message)
    StatsAggregation.populate_hourly_stats(message.to_s)
  end
  
end
