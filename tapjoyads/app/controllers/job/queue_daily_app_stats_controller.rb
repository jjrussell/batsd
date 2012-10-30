# This job populates SimpleDB with daily stats sourced from cached Vertica stats
# in S3. If it detects a mismatch between the realtime daily stat and the
# cached Vertica stat, it will overwrite the realtime value with the value in
# Vertica. This will process stats for a single day, starting at
# `last_daily_stats_aggregation_time`.

class Job::QueueDailyAppStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::APP_STATS_DAILY
    @num_reads = 10
  end

  private

  def on_message(message)
    offer_ids = JSON.parse(message.body)
    StatsAggregation.new(offer_ids).verify_hourly_and_populate_daily_stats
  end

end
