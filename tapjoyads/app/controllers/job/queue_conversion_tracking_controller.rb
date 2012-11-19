class Job::QueueConversionTrackingController < Job::SqsReaderController

  def initialize
    super QueueNames::CONVERSION_TRACKING
  end

  private

  def on_message(message)
    json = JSON.parse(message.body)
    click = Click.find(json['click_key'], :consistent => true)
    raise "Click not found: #{json['click_key']}" if click.nil?

    if json['offer_instruction_click'].present?
      click.instruction_viewed_at = Time.zone.at(json['offer_instruction_click']['viewed_at'])
      click.instruction_clicked_at = Time.zone.at(json['offer_instruction_click']['clicked_at'])
      installed_at_epoch = click.instruction_clicked_at.to_f.to_s
    else
      installed_at_epoch = json['install_timestamp']
    end

    offer = Offer.find_in_cache(click.offer_id, :do_lookup => true)
    currency = Currency.find_in_cache(click.currency_id, :do_lookup => true)

    if click.installed_at? ||
      (!click.force_convert && offer.item_type != 'GenericOffer' && click.clicked_at < (Time.zone.now - 2.days)) ||
      (!click.force_convert && click.block_reason?)
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
    attempt.ip_address             = click.ip_address
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
    attempt.device_type            = click.device_type
    attempt.geoip_country          = click.geoip_country
    attempt.store_name             = click.store_name
    attempt.created                = installed_at_epoch
    attempt.instruction_viewed_at  = click.instruction_viewed_at
    attempt.instruction_clicked_at = click.instruction_clicked_at
    attempt.save

    checker = ConversionChecker.new(click, attempt)
    if !click.force_convert && !checker.acceptable_risk?
      click.block_reason = checker.risk_message
      click.save
      attempt.block_reason = checker.risk_message
      attempt.resolution = 'blocked'
      attempt.save
      generate_web_requests(attempt)
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
    elsif click.source == 'tj_games' || click.source == 'tj_display'
      click.type = "tjm_#{click.type}"
    end

    reward = Reward.new(:key => click.reward_key)
    if reward.is_new
      reward_existed = false

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
      reward.device_type            = click.device_type
      reward.offerwall_rank         = click.offerwall_rank
      reward.store_name             = click.store_name
      reward.instruction_viewed_at  = click.instruction_viewed_at
      reward.cached_offer_list_id   = click.cached_offer_list_id
      reward.cached_offer_list_type = click.cached_offer_list_type
      reward.auditioning            = click.auditioning

      begin
        reward.save!(:expected_attr => { 'type' => nil })
      rescue Simpledb::ExpectedAttributeError => e
        reward_existed = true
      end

      unless reward_existed
        web_request = WebRequest.new(:time => Time.zone.at(installed_at_epoch.to_f))
        web_request.path               = 'reward'
        web_request.type               = reward.type
        web_request.publisher_app_id   = reward.publisher_app_id
        web_request.advertiser_app_id  = reward.advertiser_app_id
        web_request.displayer_app_id   = reward.displayer_app_id
        web_request.offer_id           = reward.offer_id
        web_request.currency_id        = reward.currency_id
        web_request.publisher_user_id  = reward.publisher_user_id
        web_request.advertiser_balance = offer.partner_balance
        web_request.advertiser_amount  = reward.advertiser_amount
        web_request.publisher_amount   = reward.publisher_amount
        web_request.displayer_amount   = reward.displayer_amount
        web_request.tapjoy_amount      = reward.tapjoy_amount
        web_request.currency_reward    = reward.currency_reward
        web_request.source             = reward.source
        web_request.udid               = reward.udid
        web_request.country            = reward.country
        web_request.exp                = reward.exp
        web_request.viewed_at          = reward.viewed_at
        web_request.click_key          = reward.click_key
        web_request.device_type        = reward.device_type
        web_request.offerwall_rank     = reward.offerwall_rank
        web_request.store_name         = reward.store_name
        web_request.instruction_viewed_at = reward.instruction_viewed_at
        web_request.save
      end
    end

    begin
      checker.process_conversion(reward)
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message, request, params)
    end

    Sqs.send_message(QueueNames::SEND_CURRENCY, reward.key) if offer.rewarded? && currency.callback_url != Currency::NO_CALLBACK_URL
    Sqs.send_message(QueueNames::CREATE_CONVERSIONS, reward.key)

    begin
      reward.update_realtime_stats
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message, request, params)
    end

    click.put('installed_at', installed_at_epoch)
    click.delete('block_reason')
    click.save
    if click.force_convert
      attempt.resolution = 'force_converted'
      attempt.force_converted_by = click.force_converted_by
    else
      attempt.resolution = 'converted'
    end
    attempt.save
    generate_web_requests(attempt)

    begin
      click.update_partner_live_dates!
    rescue => e
      Rails.logger.error "Failed to update partner live dates for click #{click}: #{e.class} #{e.message}"
    end

    device.set_last_run_time(click.advertiser_app_id)
    device.set_last_run_time(click.publisher_app_id) if !device.has_app?(click.publisher_app_id) || device.last_run_time(click.publisher_app_id) < 1.week.ago
    device.save
  end

  def generate_web_requests(attempt)
    web_request = WebRequest.new(:time => attempt.created.to_f)
    web_request.path                   = 'conversion_attempt'
    web_request.type                   = attempt.reward_type
    web_request.publisher_app_id       = attempt.publisher_app_id
    web_request.advertiser_app_id      = attempt.advertiser_app_id
    web_request.displayer_app_id       = attempt.displayer_app_id
    web_request.offer_id               = attempt.advertiser_offer_id
    web_request.currency_id            = attempt.currency_id
    web_request.publisher_user_id      = attempt.publisher_user_id
    web_request.advertiser_amount      = attempt.advertiser_amount
    web_request.publisher_amount       = attempt.publisher_amount
    web_request.displayer_amount       = attempt.displayer_amount
    web_request.tapjoy_amount          = attempt.tapjoy_amount
    web_request.currency_reward        = attempt.currency_reward
    web_request.source                 = attempt.source
    web_request.ip_address             = attempt.ip_address
    web_request.udid                   = attempt.udid
    web_request.country                = attempt.country
    web_request.viewed_at              = attempt.viewed_at
    web_request.clicked_at             = attempt.clicked_at
    web_request.store_name             = attempt.store_name
    web_request.click_key              = attempt.click_key
    web_request.mac_address            = attempt.mac_address
    web_request.device_type            = attempt.device_type
    web_request.geoip_country          = attempt.geoip_country
    web_request.conversion_attempt_key = attempt.key
    web_request.resolution             = attempt.resolution
    web_request.block_reason           = attempt.block_reason
    web_request.system_offset          = attempt.system_entities_offset
    web_request.individual_offset      = attempt.individual_entities_offset
    web_request.rules_offset           = attempt.rules_offset
    web_request.risk_score             = attempt.final_risk_score
    web_request.instruction_viewed_at  = attempt.instruction_viewed_at
    web_request.instruction_clicked_at = attempt.instruction_clicked_at
    attempt.risk_profiles.each do |key, hash|
      begin
        prefix = key.split('.').first.downcase
        attribute_name = "#{prefix}_profile_offset="
        web_request.send(attribute_name.to_sym, hash['offset'])
        attribute_name = "#{prefix}_profile_weight="
        web_request.send(attribute_name.to_sym, hash['weight'])
      rescue
        # ignore if attribute for profile is missing causing failure
      end
    end
    web_request.save

    attempt.rules_matched.each do |key, hash|
      web_request = WebRequest.new(:time => attempt.created.to_f)
      web_request.path                   = 'rule_matched'
      web_request.conversion_attempt_key = attempt.key
      web_request.rule_name              = key
      web_request.rule_offset            = hash['offset']
      web_request.rule_actions           = hash['actions']
      web_request.rule_message           = hash['message']
      web_request.save
    end
  end

end
