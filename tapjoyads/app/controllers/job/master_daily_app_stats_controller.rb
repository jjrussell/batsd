class Job::MasterDailyAppStatsController < Job::JobController

  def index
    if Offer.to_aggregate_daily_stats.count == 0
      render :text => 'ok'
      return
    end

    start_time        = (Time.zone.now - 1.day).beginning_of_day
    end_time          = start_time + 1.day
    accurate, message = StatsAggregation.check_vertica_accuracy(start_time, end_time)

    unless accurate
      Notifier.alert_new_relic(VerticaDataError, message, request, params)
      render :text => 'ok'
      return
    end

    StatsAggregation.cache_vertica_stats(start_time, end_time)

    next_aggregation_time = (Time.zone.now + 1.day).beginning_of_day + StatsAggregation::DAILY_STATS_START_HOUR.hours
    Offer.to_aggregate_daily_stats.find_in_batches(:batch_size => StatsAggregation::OFFERS_PER_MESSAGE) do |offers|
      offer_ids = offers.collect(&:id)
      Offer.connection.execute("UPDATE #{Offer.quoted_table_name} SET next_daily_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
      Sqs.send_message(QueueNames::APP_STATS_DAILY, offer_ids.to_json)
    end

    render :text => 'ok'
  end

end
