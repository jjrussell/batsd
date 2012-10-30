# This job verifies that the stats from processed records in Vertica matches
# stats from realtime stats saved in SimpleDB. Once the stats have been
# verified, the day's Vertica stats will be cached to S3. This job will then
# queue up every offer with `next_daily_stats_aggregation_time` before now to
# have its daily stats aggregated.

class Job::MasterDailyAppStatsController < Job::JobController

  def index
    if Offer.to_aggregate_daily_stats.count == 0
      render :text => 'ok'
      return
    end

    start_time        = (Time.zone.now - 1.day).beginning_of_day
    end_time          = start_time + 1.day

    unless params[:skip_check] == start_time.to_s(:yyyy_mm_dd)
      check = StatsAggregation.check_vertica_accuracy(start_time, end_time)
      if check[:stop_check] || (check[:inaccurate] && Time.zone.now.hour < 10)
        Notifier.alert_new_relic(VerticaDataError, check[:message], request, params)
        render :text => 'ok'
        return
      end
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
