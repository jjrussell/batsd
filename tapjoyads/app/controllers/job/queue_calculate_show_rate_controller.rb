class Job::QueueCalculateShowRateController < Job::SqsReaderController

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
    
    overall_clicks = StoreClick.count(:where => "click_date < '#{now.to_f - 10.minutes}' and advertiser_app_id = '#{app_key}'").to_f
    overall_installs = StoreClick.count(:where => "installed < '#{now.to_f - 10.minutes}' and advertiser_app_id = '#{app_key}'").to_f
    
    if overall_installs == 0 or overall_clicks == 0
      conversion_rate = app.get('price').to_f > 0 ? 0.3 : 0.75
    else
      conversion_rate = overall_installs / overall_clicks
    end
    
    min_conversion_rate = app.get('price').to_f > 0 ? 0.02 : 0.4
    if overall_clicks > 30 and conversion_rate < min_conversion_rate
      NewRelic::Agent.agent.error_collector.notice_error(
          Exception.new("App #{app_key} (#{app.get('name')}) has #{conversion_rate} cvr on #{overall_clicks} clicks."))
    end
    
    Rails.logger.info "Overall clicks: #{overall_clicks}"
    Rails.logger.info "Overall installs: #{overall_installs}"
    Rails.logger.info "cvr: #{conversion_rate}"
    
    clicks = StoreClick.count(:where => "click_date > '#{now.to_f - timeframe}' and advertiser_app_id = '#{app_key}'").to_f
    installs = StoreClick.count(:where => "installed > '#{now.to_f - timeframe}' and advertiser_app_id = '#{app_key}'").to_f
    
    possible_clicks_per_second = clicks / timeframe / old_show_rate
    
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
    
    balance = app.get('balance').to_f
    payment_for_install = app.get('payment_for_install').to_f
    target_installs = balance / payment_for_install
    
    daily_budget = app.get('daily_budget')
    if daily_budget and daily_budget.to_i > 0
      target_installs = [daily_budget.to_f - num_installs_today, target_installs].min
    end
    
    target_clicks = target_installs / conversion_rate
    
    Rails.logger.info "Balance: #{balance}"
    Rails.logger.info "Payment for install: #{payment_for_install}"
    Rails.logger.info "Daily budget: #{daily_budget}"
    Rails.logger.info "Target installs for remainder of day: #{target_installs}"
    Rails.logger.info "Target clicks for remainder of day: #{target_clicks}"
    
    if target_clicks <= 0
      new_show_rate = 0
    else
      new_show_rate = target_clicks / (possible_clicks_per_second * seconds_left_in_day)
      new_show_rate = 1 if new_show_rate > 1
    end

    if old_show_rate == 0 and target_installs > 0
      Rails.logger.info "Setting new show rate to 0.1, since old show rate was 0."
      new_show_rate = 0.1
    end
    
    Rails.logger.info "New show_rate: #{new_show_rate}"
    
    app.put('show_rate', new_show_rate)
    app.save
  end
end