class Job::MasterDailyAppStatsController < Job::JobController

  def index
    if Offer.to_aggregate_daily_stats.count == 0 || vertica_data_inaccurate?
      render :text => 'ok'
      return
    end

    next_aggregation_time = (Time.zone.now + 1.day).beginning_of_day + StatsAggregation::DAILY_STATS_START_HOUR.hours
    Offer.to_aggregate_daily_stats.find_in_batches(:batch_size => StatsAggregation::OFFERS_PER_MESSAGE) do |offers|
      offer_ids = offers.collect(&:id)
      Offer.connection.execute("UPDATE #{Offer.quoted_table_name} SET next_daily_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
      Sqs.send_message(QueueNames::APP_STATS_DAILY, offer_ids.to_json)
    end

    render :text => 'ok'
  end

  private

  def vertica_data_inaccurate?
    start_time = (Time.zone.now - 1.day).beginning_of_day
    end_time   = start_time + 1.day

    appstats_counts = Appstats.new(nil, {
        :stat_prefix => 'global',
        :start_time  => start_time,
        :end_time    => end_time,
        :stat_types  => [ 'featured_offers_requested' ],
        :granularity => :hourly }).stats['featured_offers_requested']
    vertica_counts = {}
    WebRequest.select_with_vertica(
        :select     => "count(*), floor((time - #{start_time.to_i}) / #{1.hour.to_i}) as h",
        :conditions => "path LIKE '%featured_offer_requested%' AND time >= #{start_time.to_i} AND time < #{end_time.to_i}",
        :group      => 'h').each do |result|
      vertica_counts[result[:h].to_i] = result[:count]
    end

    appstats_total = appstats_counts.sum
    vertica_total  = vertica_counts.values.sum
    percentage     = vertica_total / appstats_total.to_f
    inaccurate     = percentage < 0.99999 || percentage > 1.00001

    if inaccurate
      message  = "Cannot verify daily stats because Vertica has inaccurate data for #{start_time.to_date}.\n"
      message += "Appstats total: #{appstats_total}\n"
      message += "Vertica total: #{vertica_total}\n"
      message += "Difference: #{appstats_total - vertica_total}\n\n"
      message += "hour, appstats, vertica, diff\n"
      24.times do |i|
        appstats_val = appstats_counts[i]
        vertica_val  = vertica_counts[i] || 0
        message += "#{i}, #{appstats_val}, #{vertica_val}, #{appstats_val - vertica_val}\n"
      end
      Notifier.alert_new_relic(VerticaDataError, message, request, params)
    end

    inaccurate
  end

end
