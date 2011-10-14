class Job::QueueHourlyAppStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::APP_STATS_HOURLY
  end

  private

  def on_message(message)
    offer_ids = JSON.parse(message.to_s)
    StatsAggregation.new(offer_ids).populate_hourly_stats
  end

end
