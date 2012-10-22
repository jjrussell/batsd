class Job::QueueHourlyAppStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::APP_STATS_HOURLY
    @num_reads = 5
  end

  private

  def on_message(message)
    offer_ids = JSON.parse(message.body)
    StatsAggregation.new(offer_ids).populate_hourly_stats
  end

end
