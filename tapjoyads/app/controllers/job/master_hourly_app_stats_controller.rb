class Job::MasterHourlyAppStatsController < Job::JobController

  def index
    next_aggregation_time = Time.zone.now + 1.hour

    Offer.to_aggregate_hourly_stats.find_in_batches(:batch_size => StatsAggregation::OFFERS_PER_MESSAGE) do |offers|
      offer_ids = offers.map(&:id)
      Offer.connection.execute("UPDATE offers SET next_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
      Sqs.send_message(QueueNames::APP_STATS_HOURLY, offer_ids.to_json)
    end

    render :text => 'ok'
  end

end
