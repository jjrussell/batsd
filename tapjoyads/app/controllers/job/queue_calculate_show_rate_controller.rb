class Job::QueueCalculateShowRateController < Job::SqsReaderController

  def initialize
    super QueueNames::CALCULATE_SHOW_RATE
  end

  def on_message(message)
    offer = Offer.find(message.to_s)
    
    Rails.logger.info "Calculating new show_rate for offer #{offer.name} (#{offer.id})"
    
    if offer.payment <= 0
      offer.show_rate = 0
      offer.save!
      return
    end
    
    old_show_rate = offer.show_rate
    
    now = Time.now.utc
    
    cvr_timeframe = offer.is_free? ? 1.hour : 24.hours
    recent_clicks = StoreClick.count(:where => "click_date > '#{now.to_f - cvr_timeframe}' and click_date < '#{now.to_f - 5.minutes}' and advertiser_app_id = '#{offer.id}'", :retries => 1000).to_f
    recent_installs = StoreClick.count(:where => "click_date > '#{now.to_f - cvr_timeframe}' and click_date < '#{now.to_f - 5.minutes}' and installed != '' and advertiser_app_id = '#{offer.id}'", :retries => 1000).to_f
    
    if recent_clicks == 0
      conversion_rate = offer.is_paid? ? 0.3 : 0.75
    else
      conversion_rate = recent_installs / recent_clicks
    end
    
    min_conversion_rate = offer.min_conversion_rate || (offer.is_paid? ? 0.005 : 0.12)
    if recent_clicks > 100 && conversion_rate < min_conversion_rate
      Notifier.alert_new_relic(ConversionRateTooLowError, "Offer #{offer.name} (#{offer.id}) has #{conversion_rate} cvr on #{recent_clicks} clicks.")
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
    
    # Assume all apps are CST for now.
    end_of_day = Time.parse('00:00 CST', Time.now.utc + 18.hours).utc
    seconds_left_in_day = end_of_day - now
    num_installs_today = StoreClick.count(:where => "installed > '#{end_of_day.to_f - 24.hours}' and advertiser_app_id = '#{offer.id}'", :retries => 1000).to_f
    
    Rails.logger.info "Seconds left in day: #{seconds_left_in_day}"
    Rails.logger.info "Num installs today: #{num_installs_today}"
    
    target_installs = 1.0 / 0
    
    if offer.daily_budget && offer.daily_budget > 0
      target_installs = [offer.daily_budget.to_f - num_installs_today, target_installs].min
    end
    
    unless offer.allow_negative_balance?
      max_paid_installs = offer.partner.balance / offer.payment
      target_installs = max_paid_installs if target_installs > max_paid_installs
    end
    
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

    if old_show_rate == 0 and target_installs > 0
      Rails.logger.info "Setting new show rate to 0.01, since old show rate was 0."
      new_show_rate = 0.01
    end
    
    # For low budget apps, don't just change to the new show_rate if it is larger than the old show_rate.
    # Instead, just add 2%. This prevents a period of 20 minutes with no clicks from causing the
    # show_rate to jump to 100% on the next run.
    if offer.daily_budget && offer.daily_budget > 0 && offer.daily_budget < 5000 && new_show_rate > old_show_rate
      new_show_rate = [new_show_rate, old_show_rate + 0.02].min
    end
    
    if offer.daily_budget && offer.daily_budget > 0 && num_installs_today > offer.daily_budget
      Rails.logger.info "Pushed too many installs. Overriding any calculations and setting show rate to 0."
      new_show_rate = 0
    end
    
    if offer.overall_budget && offer.overall_budget > 0
      total_installs = StoreClick.count(:where => "installed != '' and advertiser_app_id = '#{offer.id}'", :retries => 1000).to_f
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