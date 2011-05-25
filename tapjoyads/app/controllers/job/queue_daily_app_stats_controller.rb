class Job::QueueDailyAppStatsController < Job::SqsReaderController
  
  def initialize
    super QueueNames::APP_STATS_DAILY
    @num_reads = 10
  end
  
private
  
  def on_message(message)
    StoreRank.populate_daily_ranks(message.to_s)
    StatsAggregation.verify_hourly_and_populate_daily_stats(message.to_s)
  end
  
end
