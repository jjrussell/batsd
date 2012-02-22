class Job::QueueCalculateShowRateController < Job::SqsReaderController

  def initialize
    super QueueNames::CALCULATE_SHOW_RATE
  end

  private

  def on_message(message)
    offer = Offer.find(message.body)

    return if offer.payment == 0

    Rails.logger.info "Calculating new show_rate for offer #{offer.name} (#{offer.id})"

    old_show_rate = offer.show_rate

    now = Time.zone.now
    start_time = offer.is_free? ? (now.beginning_of_hour - 1.hour) : (now.beginning_of_hour - 1.day)
    appstats = Appstats.new(offer.id, { :start_time => start_time, :end_time => now, :stat_types => %w(paid_clicks paid_installs jailbroken_installs) })
    cvr_timeframe = appstats.end_time - appstats.start_time

    recent_clicks = appstats.stats['paid_clicks'].sum.to_f
    recent_installs = appstats.stats['paid_installs'].sum.to_f + appstats.stats['jailbroken_installs'].sum.to_f

    if recent_clicks == 0
      conversion_rate = offer.is_paid? ? 0.3 : 0.75
    else
      conversion_rate = recent_installs / recent_clicks
    end

    conversion_rate = 1.0 if conversion_rate > 1.0

    min_conversion_rate = offer.calculate_min_conversion_rate
    if recent_clicks > 200 && conversion_rate < min_conversion_rate && offer.send_low_conversion_email?
      stats = {
        :recent_clicks => recent_clicks,
        :recent_installs => recent_installs,
        :conversion_rate => conversion_rate,
        :min_conversion_rate => min_conversion_rate,
      }
      TapjoyMailer.deliver_low_conversion_rate_warning(offer, stats)
    end

    Rails.logger.info "Recent clicks: #{recent_clicks}"
    Rails.logger.info "Recent installs: #{recent_installs}"
    Rails.logger.info "cvr: #{conversion_rate}"

    possible_clicks_per_second = recent_clicks / cvr_timeframe / old_show_rate

    # Assume a higher click/second rate than reality. This helps ensure that budgets come in slightly
    # under, rather than slightly over.
    possible_clicks_per_second = 1.1 * possible_clicks_per_second

    Rails.logger.info "Old show_rate: #{old_show_rate}"
    Rails.logger.info "Possible clicks per second: #{possible_clicks_per_second}"

    possible_installs_per_second = possible_clicks_per_second * conversion_rate * old_show_rate
    potential_spend = (possible_installs_per_second * 48.hours) * offer.payment
    offer.low_balance = (potential_spend > offer.partner.balance)

    # Assume all apps are CST for now.
    end_of_cst_day = Time.parse('00:00 CST', now + 18.hours).utc
    seconds_left_in_day = end_of_cst_day - now
    appstats_cst = Appstats.new(offer.id, { :start_time => (end_of_cst_day - 1.day), :end_time => end_of_cst_day, :stat_types => %w(paid_installs) })
    num_installs_today = appstats_cst.stats['paid_installs'].sum

    Rails.logger.info "Seconds left in day: #{seconds_left_in_day}"
    Rails.logger.info "Num installs today: #{num_installs_today}"

    target_installs = offer.calculate_target_installs(num_installs_today)
    target_clicks = target_installs / conversion_rate

    Rails.logger.info "Daily budget: #{offer.daily_budget}"
    Rails.logger.info "Target installs for remainder of day: #{target_installs}"
    Rails.logger.info "Target clicks for remainder of day: #{target_clicks}"

    if target_clicks <= 0
      new_show_rate = 0
    else
      new_show_rate = target_clicks / (possible_clicks_per_second * seconds_left_in_day)
      new_show_rate = 1 if new_show_rate > 1
    end

    if old_show_rate == 0 && target_installs > 0
      Rails.logger.info "Setting new show rate to 0.01, since old show rate was 0."
      new_show_rate = 0.01
    end

    # For low budget apps, don't just change to the new show_rate if it is larger than the old show_rate.
    # Instead, just add 2%. This prevents a period of 20 minutes with no clicks from causing the
    # show_rate to jump to 100% on the next run.
    if offer.daily_budget > 0 && offer.daily_budget < 5000 && new_show_rate > old_show_rate
      new_show_rate = [new_show_rate, old_show_rate + 0.02].min
    end

    if offer.daily_budget > 0 && num_installs_today > offer.daily_budget
      Rails.logger.info "Pushed too many installs. Overriding any calculations and setting show rate to 0."
      new_show_rate = 0
    end

    if offer.overall_budget > 0
      appstats_overall = Appstats.new(offer.id, { :start_time => Time.zone.parse('2010-01-01'), :end_time => now, :stat_types => %w(paid_installs) })
      total_installs = appstats_overall.stats['paid_installs'].sum
      if total_installs > offer.overall_budget
        Rails.logger.info "App over overall_budget. Overriding any calculations and setting show rate to 0."
        new_show_rate = 0
      end
    end

    if new_show_rate.to_f.nan?
      Rails.logger.info "Adjusted show_rate to 0.0 because it was NaN"
      new_show_rate = 0
    end

    Rails.logger.info "New show_rate: #{new_show_rate}"

    offer.conversion_rate = conversion_rate
    offer.show_rate = new_show_rate
    offer.save!
  end
end
