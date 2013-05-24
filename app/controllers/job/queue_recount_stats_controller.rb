class Job::QueueRecountStatsController < Job::SqsReaderController

  def initialize
    super QueueNames::RECOUNT_STATS
  end

  private

  def on_message(message)
    json = JSON.parse(message.body)
    start_time = Time.zone.at(json['start_time'])
    end_time = Time.zone.at(json['end_time'])

    StatsAggregation.new(json['offer_ids']).recount_stats_over_range(start_time, end_time, json['update_daily'])
  end

end
