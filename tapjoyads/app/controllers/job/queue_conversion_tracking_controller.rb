class Job::QueueConversionTrackingController < Job::SqsReaderController

  def initialize
    super QueueNames::CONVERSION_TRACKING
  end

  private

  def on_message(message)
    json = JSON.parse(message.body)
    click = Click.find(json['click_key'], :consistent => true)
    raise "Click not found: #{json['click_key']}" if click.nil?
    installed_at_epoch = json['install_timestamp']

    offer = Offer.find_in_cache(click.offer_id, true)
    currency = Currency.find_in_cache(click.currency_id, true)

    if click.installed_at? || (offer.item_type != 'GenericOffer' && click.clicked_at < (Time.zone.now - 2.days)) || click.block_reason?
      return
    end

    # TODO: may have multiple conversion attempts per click, so should not use the reward_key as key for conversion attempt
    attempt = ConversionAttempt.new(:key => click.reward_key)
    attempt.reward_type            = click.type
    attempt.publisher_app_id       = click.publisher_app_id
    attempt.advertiser_app_id      = click.advertiser_app_id
    attempt.displayer_app_id       = click.displayer_app_id
    attempt.advertiser_offer_id    = click.offer_id
    attempt.currency_id            = click.currency_id
    attempt.publisher_user_id      = click.publisher_user_id
    attempt.advertiser_amount      = click.advertiser_amount
    attempt.publisher_amount       = click.publisher_amount
    attempt.displayer_amount       = click.displayer_amount
    attempt.currency_reward        = click.currency_reward
    attempt.tapjoy_amount          = click.tapjoy_amount
    attempt.source                 = click.source
    attempt.udid                   = click.udid
    attempt.country                = click.country
    attempt.viewed_at              = click.viewed_at
    attempt.clicked_at             = click.clicked_at
    attempt.click_key              = click.key
    attempt.publisher_partner_id   = click.publisher_partner_id || currency.partner_id
    attempt.advertiser_partner_id  = click.advertiser_partner_id || offer.partner_id
    attempt.publisher_reseller_id  = click.publisher_reseller_id || currency.reseller_id
    attempt.advertiser_reseller_id = click.advertiser_reseller_id || offer.reseller_id
    attempt.spend_share            = click.spend_share || currency.get_spend_share(offer)
    attempt.mac_address            = click.mac_address
    attempt.save

    checker = ConversionChecker.new(click, attempt)
    unless checker.acceptable_risk?
      click.block_reason = checker.risk_message
      click.save
      attempt.block_reason = checker.risk_message
      attempt.resolution = 'blocked'
      attempt.save
      return
    end

    unless click.reward_key
      raise "Click #{click.key} missing reward key!"
    end

    device = Device.new(:key => click.udid)
    if device.is_jailbroken && offer.is_paid? && offer.item_type == 'App' && click.type == 'install'
      click.tapjoy_amount += click.advertiser_amount
      click.advertiser_amount = 0
      click.type += '_jailbroken'
      Notifier.alert_new_relic(JailbrokenInstall, "Device: #{click.udid} is jailbroken and installed a paid app: #{click.advertiser_app_id}, for click: #{click.key}", request, params)
    end

    if click.source == 'featured'
      click.type = "featured_#{click.type}"
    elsif click.source == 'tj_games'
      click.type = "tjm_#{click.type}"
    end

    reward = Reward.new(:key => click.reward_key)
    reward.put('created', installed_at_epoch)
    reward.type                   = click.type
    reward.publisher_app_id       = click.publisher_app_id
    reward.advertiser_app_id      = click.advertiser_app_id
    reward.displayer_app_id       = click.displayer_app_id
    reward.offer_id               = click.offer_id
    reward.currency_id            = click.currency_id
    reward.publisher_user_id      = click.publisher_user_id
    reward.advertiser_amount      = click.advertiser_amount
    reward.publisher_amount       = click.publisher_amount
    reward.displayer_amount       = click.displayer_amount
    reward.currency_reward        = click.currency_reward
    reward.tapjoy_amount          = click.tapjoy_amount
    reward.source                 = click.source
    reward.udid                   = click.udid
    reward.country                = click.country
    reward.reward_key_2           = click.reward_key_2
    reward.exp                    = click.exp
    reward.viewed_at              = click.viewed_at
    reward.click_key              = click.key
    reward.publisher_partner_id   = click.publisher_partner_id || currency.partner_id
    reward.advertiser_partner_id  = click.advertiser_partner_id || offer.partner_id
    reward.publisher_reseller_id  = click.publisher_reseller_id || currency.reseller_id
    reward.advertiser_reseller_id = click.advertiser_reseller_id || offer.reseller_id
    reward.spend_share            = click.spend_share || currency.get_spend_share(offer)
    reward.mac_address            = click.mac_address

    begin
      reward.save!(:expected_attr => { 'type' => nil })
    rescue Simpledb::ExpectedAttributeError => e
      return
    end
    checker.process_conversion(reward)

    Sqs.send_message(QueueNames::SEND_CURRENCY, reward.key) if offer.rewarded? && currency.callback_url != Currency::NO_CALLBACK_URL
    Sqs.send_message(QueueNames::CREATE_CONVERSIONS, reward.key)

    begin
      reward.update_realtime_stats
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message, request, params)
    end

    click.put('installed_at', installed_at_epoch)
    click.save
    attempt.resolution = 'converted'
    attempt.save

    begin
      click.update_partner_live_dates!
    rescue => e
      Rails.logger.error "Failed to update partner live dates for click #{click}: #{e.class} #{e.message}"
    end

    device.set_last_run_time(click.advertiser_app_id)
    device.set_last_run_time(click.publisher_app_id) if !device.has_app?(click.publisher_app_id) || device.last_run_time(click.publisher_app_id) < 1.week.ago
    device.save

    web_request = WebRequest.new(:time => Time.zone.at(installed_at_epoch.to_f))
    web_request.path              = 'reward'
    web_request.type              = reward.type
    web_request.publisher_app_id  = reward.publisher_app_id
    web_request.advertiser_app_id = reward.advertiser_app_id
    web_request.displayer_app_id  = reward.displayer_app_id
    web_request.offer_id          = reward.offer_id
    web_request.currency_id       = reward.currency_id
    web_request.publisher_user_id = reward.publisher_user_id
    web_request.advertiser_amount = reward.advertiser_amount
    web_request.publisher_amount  = reward.publisher_amount
    web_request.displayer_amount  = reward.displayer_amount
    web_request.tapjoy_amount     = reward.tapjoy_amount
    web_request.currency_reward   = reward.currency_reward
    web_request.source            = reward.source
    web_request.udid              = reward.udid
    web_request.country           = reward.country
    web_request.exp               = reward.exp
    web_request.viewed_at         = reward.viewed_at
    web_request.click_key         = reward.click_key
    web_request.save
  end
end
