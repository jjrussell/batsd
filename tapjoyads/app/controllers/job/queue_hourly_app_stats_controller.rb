# This job takes realtime hourly stats that have been stored in Memcache and persists them to SimpleDB.
# It will process stats from `last_stats_aggregation_time` until the beginning of the current hour.

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
