# This job updates partners stats counts by summing stats counts across all of its offers.
# It will process stats for the current day.

class Job::QueueHourlyPartnerStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::PARTNER_STATS_HOURLY
    @num_reads = 5
  end

  private

  def on_message(message)
    partner_ids = JSON.parse(message.body)
    StatsAggregation.new(partner_ids).aggregate_stats_for_partners
  end

end
