class Job::QueueCalculateShowRateController < Job::SqsReaderController
  include NewRelicHelper

  def initialize
    super QueueNames::CALCULATE_SHOW_RATE
  end

  def on_message(message)
    app_key = message.to_s
    app = App.new(:key => app_key)
    
    Rails.logger.info "Calculating new show_rate for #{app_key}, #{app.get('name')}"
    
    old_show_rate = app.get('show_rate') || 1
    old_show_rate = old_show_rate.to_f
    
    now = Time.now.utc
    timeframe = 20.minutes
    
    cvr_timeframe = app.is_free ? 1.hour : 24.hours
    recent_clicks = StoreClick.count(:where => "click_date > '#{now.to_f - cvr_timeframe}' and advertiser_app_id = '#{app_key}'").to_f
    recent_installs = StoreClick.count(:where => "installed > '#{now.to_f - cvr_timeframe}' and advertiser_app_id = '#{app_key}'").to_f
    
    if recent_clicks == 0
      conversion_rate = app.get('price').to_f > 0 ? 0.3 : 0.75
    else
      conversion_rate = recent_installs / recent_clicks
    end
    
    min_conversion_rate = app.get('price').to_f > 0 ? 0.005 : 0.12
    min_conversion_rate = app.get('min_cvr').to_f if app.get('min_cvr')
    if recent_clicks > 100 and conversion_rate < min_conversion_rate
      alert_new_relic(ConversionRateTooLowError,
        "App #{app.to_s} has #{conversion_rate} cvr on #{recent_clicks} clicks.")
    end
    
    Rails.logger.info "Recent clicks: #{recent_clicks}"
    Rails.logger.info "Recent installs: #{recent_installs}"
    Rails.logger.info "cvr: #{conversion_rate}"
    
    clicks = StoreClick.count(:where => "click_date > '#{now.to_f - timeframe}' and advertiser_app_id = '#{app_key}'").to_f
    installs = StoreClick.count(:where => "installed > '#{now.to_f - timeframe}' and advertiser_app_id = '#{app_key}'").to_f
    
    possible_clicks_per_second = clicks / timeframe / old_show_rate
    
    # Assume a higher click/second rate than reality. This helps ensure that budgets come in slightly
    # under, rather than slightly over.
    possible_clicks_per_second = 1.1 * possible_clicks_per_second
    
    Rails.logger.info "Clicks last 20 mins: #{clicks}"
    Rails.logger.info "Installs last 20 mins: #{installs}"
    Rails.logger.info "Old show_rate: #{old_show_rate}"
    Rails.logger.info "Possible clicks per second: #{possible_clicks_per_second}"
    
    # Assume all apps are CST for now.
    end_of_day = Time.parse('00:00 CST', Time.now.utc + 18.hours).utc
    seconds_left_in_day = end_of_day - now
    num_installs_today = StoreClick.count(:where => "installed > '#{end_of_day.to_f - 24.hours}' and advertiser_app_id = '#{app_key}'").to_f
    
    Rails.logger.info "Seconds left in day: #{seconds_left_in_day}"
    Rails.logger.info "Num installs today: #{num_installs_today}"
    
    # Disabled - uncomment to set upper limit based on balance.
    #balance = app.get('balance').to_f
    #payment_for_install = app.get('payment_for_install').to_f
    #target_installs = balance / payment_for_install
    
    target_installs = 1.0 / 0
    
    if app.daily_budget > 0
      target_installs = [app.daily_budget.to_f - num_installs_today, target_installs].min
    end
    
    target_clicks = target_installs / conversion_rate
    
    Rails.logger.info "Daily budget: #{app.daily_budget}"
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
    if app.daily_budget < 5000 and new_show_rate > old_show_rate
      new_show_rate = [new_show_rate, old_show_rate + 0.02].min
    end
    
    if app.daily_budget > 0 and num_installs_today > app.daily_budget
      Rails.logger.info "Pushed too many installs. Overriding any calculations and setting show rate to 0."
      new_show_rate = 0
    end
    
    Rails.logger.info "New show_rate: #{new_show_rate}"
    
    app.put('conversion_rate', conversion_rate)
    app.put('show_rate', new_show_rate)
    app.save
  end
end