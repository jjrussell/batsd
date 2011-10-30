class Job::MasterDailyAppStatsController < Job::JobController

  def index
    if Offer.to_aggregate_daily_stats.count == 0
      render :text => 'ok'
      return
    end

    now        = Time.zone.now
    start_time = (now - 1.day).beginning_of_day
    end_time   = start_time + 1.day

    appstats_counts = Appstats.new(nil, {
        :stat_prefix => 'global',
        :start_time  => start_time,
        :end_time    => end_time,
        :stat_types  => [ 'featured_offers_requested' ],
        :granularity => :hourly }).stats['featured_offers_requested']
    vertica_counts = WebRequest.select_with_vertica(
        :select     => "count(*), floor((time - #{start_time.to_i}) / #{1.hour.to_i}) as h",
        :conditions => "path LIKE '%featured_offer_requested%' AND time >= #{start_time.to_i} AND time < #{end_time.to_i}",
        :group      => 'h',
        :order      => 'h ASC').map { |result| result[:count] }

    appstats_total = appstats_counts.sum
    vertica_total  = vertica_counts.sum
    percentage     = vertica_total / appstats_total.to_f
    if percentage < 0.99999 || percentage > 1.00001
      message  = "Cannot verify daily stats because Vertica has inaccurate data.\n"
      message += "Appstats total: #{appstats_total}\n"
      message += "Vertica total: #{vertica_total}\n"
      message += "Difference: #{appstats_total - vertica_total}\n\n"
      message += "hour, appstats, vertica, diff\n"
      24.times do |i|
        message += "#{i}, #{appstats_counts[i]}, #{vertica_counts[i]}, #{appstats_counts[i] - vertica_counts[i]}\n"
      end
      Notifier.alert_new_relic(VerticaDataError, message, request, params)
      render :text => 'ok'
      return
    end

    next_aggregation_time = (now + 1.day).beginning_of_day + StatsAggregation::DAILY_STATS_START_HOUR.hours
    Offer.to_aggregate_daily_stats.find_in_batches(:batch_size => StatsAggregation::OFFERS_PER_MESSAGE) do |offers|
      offer_ids = offers.collect(&:id)
      Offer.connection.execute("UPDATE #{Offer.quoted_table_name} SET next_daily_stats_aggregation_time = '#{next_aggregation_time.to_s(:db)}' WHERE id IN ('#{offer_ids.join("','")}')")
      Sqs.send_message(QueueNames::APP_STATS_DAILY, offer_ids.to_json)
    end

    render :text => 'ok'
  end

end
