class Job::MasterDailyAppStatsController < Job::JobController

  def index
    if Offer.to_aggregate_daily_stats.count == 0
      render :text => 'ok'
      return
    end

    start_time    = (Time.zone.now - 1.day).beginning_of_day
    end_time      = start_time + 1.day
    stats_count   = Appstats.new(nil, { :stat_prefix => 'global', :start_time => start_time, :end_time => end_time, :stat_types => [ 'featured_offers_requested' ], :granularity => :hourly }).stats['featured_offers_requested'].sum
    vertica_count = WebRequest.count_with_vertica("path LIKE '%featured_offer_requested%' AND time >= #{start_time.to_i} AND time < #{end_time.to_i}")
    percentage    = vertica_count / stats_count.to_f
    if percentage < 0.99999 || percentage > 1.00001
      Notifier.alert_new_relic(AppStatsVerifyError, "Cannot verify daily stats because Vertica is missing data. Appstats count: #{stats_count}, Vertica count: #{vertica_count}", request, params)
      render :text => 'ok'
      return
    end

    next_aggregation_time = Time.zone.now + 1.day
    offer_ids = Offer.to_aggregate_daily_stats.collect(&:id)

    Offer.connection.execute("UPDATE offers SET next_daily_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")

    offer_ids.each_slice(StatsAggregation::OFFERS_PER_MESSAGE) do |ids|
      Sqs.send_message(QueueNames::APP_STATS_DAILY, ids.to_json)
    end

    render :text => 'ok'
  end

end
