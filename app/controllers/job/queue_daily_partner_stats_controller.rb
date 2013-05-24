# This job will aggregate partner daily stats for the previous day

class Job::QueueDailyPartnerStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::PARTNER_STATS_DAILY
    @num_reads = 10
  end

  private

  def on_message(message)
    partner_ids = JSON.parse(message.body)
    StatsAggregation.new(partner_ids).aggregate_stats_for_partners((Time.zone.now - 1.day).beginning_of_day, true)
  end

end
