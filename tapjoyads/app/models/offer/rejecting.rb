module Offer::Rejecting

  ALREADY_COMPLETE_IDS = {
    # Tap Farm
    [ '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424' ] => [ '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424', 'bad4b0ae-8458-42ba-97ba-13b302827234', '403014c2-9a1b-4c1d-8903-5a41aa09be0e' ],
    # Tap Store
    [ 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91' ] => [ 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91', 'a994587c-390c-4295-a6b6-dd27713030cb', '6703401f-1cb2-42ec-a6a4-4c191f8adc27' ],
    # Clubworld
    [ '3885c044-9c8e-41d4-b136-c877915dda91' ] => [ '3885c044-9c8e-41d4-b136-c877915dda91', 'a3980ac5-7d33-43bc-8ba1-e4598c7ed279' ],
    # Groupon
    [ '7f44c068-6fa1-482c-b2d2-770edcf8f83d', '192e6d0b-cc2f-44c2-957c-9481e3c223a0' ] => [ '7f44c068-6fa1-482c-b2d2-770edcf8f83d', '192e6d0b-cc2f-44c2-957c-9481e3c223a0' ],
    # My Town 2
    [ 'cab56716-8e27-4a4c-8477-457e1d311209', '069eafb8-a9b8-4293-8d2a-e9d9ed659ac8' ] => [ 'cab56716-8e27-4a4c-8477-457e1d311209', '069eafb8-a9b8-4293-8d2a-e9d9ed659ac8' ],
    # Snoopy's Street Fair
    [ '99d4a403-38a8-41e3-b7a2-5778acb968ef', 'b22f3ef8-947f-4605-a5bc-a83609af5ab7' ] => [ '99d4a403-38a8-41e3-b7a2-5778acb968ef', 'b22f3ef8-947f-4605-a5bc-a83609af5ab7' ],
    # Pocket Potions
    [ '7158f47a-9cad-4956-9cef-8f0bb4cef0af', 'c71463b5-b5bd-488d-b435-f78155fb7f85' ] => [ '7158f47a-9cad-4956-9cef-8f0bb4cef0af', 'c71463b5-b5bd-488d-b435-f78155fb7f85' ],
  }

  def postcache_reject?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version, screen_layout_size, video_offer_ids, source)
    geoip_reject?(geoip_data, device) ||
    already_complete?(device, app_version) ||
    selective_opt_out_reject?(device) ||
    show_rate_reject?(device) ||
    flixter_reject?(publisher_app, device) ||
    minimum_bid_reject?(currency, type) ||
    jailbroken_reject?(device) ||
    direct_pay_reject?(direct_pay_providers) ||
    action_app_reject?(device) ||
    min_os_version_reject?(os_version) ||
    cookie_tracking_reject?(publisher_app, library_version, source) ||
    screen_layout_sizes_reject?(screen_layout_size) ||
    is_disabled?(publisher_app, currency) ||
    age_rating_reject?(currency) ||
    publisher_whitelist_reject?(publisher_app) ||
    currency_whitelist_reject?(currency) ||
    video_offers_reject?(video_offer_ids, type) ||
    frequency_capping_reject?(device) ||
    tapjoy_games_retargeting_reject?(device)
  end

  def precache_reject?(platform_name, hide_rewarded_app_installs, normalized_device_type)
    app_platform_mismatch?(platform_name) || hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) || device_platform_mismatch?(normalized_device_type)
  end

  def is_valid_for?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version, screen_layout_size)
    (is_test_device?(currency, device) &&
      is_test_video_offer?(type) ) ||
    (!(is_test_video_offer?(type) ||
      device_platform_mismatch?(Device.normalize_device_type(device_type)) ||
      geoip_reject?(geoip_data, device) ||
      already_complete?(device, app_version) ||
      flixter_reject?(publisher_app, device) ||
      minimum_bid_reject?(currency, type) ||
      jailbroken_reject?(device) ||
      direct_pay_reject?(direct_pay_providers) ||
      action_app_reject?(device) ||
      hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) ||
      min_os_version_reject?(os_version) ||
      screen_layout_sizes_reject?(screen_layout_size) ||
      is_disabled?(publisher_app, currency) ||
      app_platform_mismatch?(publisher_app) ||
      age_rating_reject?(currency) ||
      publisher_whitelist_reject?(publisher_app) ||
      currency_whitelist_reject?(currency) ||
      frequency_capping_reject?(device)) &&
      accepting_clicks?)
  end

  def frequency_capping_reject?(device)
    return false unless multi_complete? && interval != Offer::FREQUENCIES_CAPPING_INTERVAL['none']

    device.has_app?(item_id) && (device.last_run_time(item_id) + interval > Time.zone.now)
  end

  private

  def is_disabled?(publisher_app, currency)
    item_id == currency.app_id ||
      currency.get_disabled_offer_ids.include?(item_id) ||
      currency.get_disabled_offer_ids.include?(id) ||
      currency.get_disabled_partner_ids.include?(partner_id) ||
      (currency.only_free_offers? && is_paid?) ||
      (self_promote_only? && partner_id != publisher_app.partner_id)
  end

  def device_platform_mismatch?(normalized_device_type)
    return false if normalized_device_type.blank?

    !get_device_types.include?(normalized_device_type)
  end

  def app_platform_mismatch?(app_platform_name)
    return false if app_platform_name.blank?

    platform_name = get_platform
    platform_name != 'All' && platform_name != app_platform_name
  end

  def age_rating_reject?(currency)
    return false if currency.max_age_rating.nil?
    return false if age_rating.nil?
    currency.max_age_rating < age_rating
  end

  def geoip_reject?(geoip_data, device)
    return true if countries.present? && countries != '[]' && !get_countries.include?(geoip_data[:country])
    return true if geoip_data[:country] && get_countries_blacklist.include?(geoip_data[:country].to_s.upcase)
    return true if regions.present? && regions != '[]' && !get_regions.include?(geoip_data[:region])
    return true if dma_codes.present? && dma_codes != '[]' && !get_dma_codes.include?(geoip_data[:dma_code])

    false
  end

  def already_complete?(device, app_version = nil)
    return false if multi_complete?

    app_id_for_device = item_id
    if item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(item_id, app_version)
    end

    ALREADY_COMPLETE_IDS.each do |target_ids, ids_to_reject|
      if target_ids.include?(app_id_for_device)
        return true if ids_to_reject.any? { |reject_id| device.has_app?(reject_id) }
      end
    end

    device.has_app?(app_id_for_device)
  end

  def selective_opt_out_reject?(device)
    device.opt_out_offer_types.include?(item_type)
  end

  def show_rate_reject?(device)
    srand( (device.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    should_reject = rand > show_rate
    srand

    should_reject
  end

  def flixter_reject?(publisher_app, device)
    clash_of_titans_offer_id = '4445a5be-9244-4ce7-b65d-646ee6050208'
    tap_fish_id = '9dfa6164-9449-463f-acc4-7a7c6d7b5c81'
    tap_fish_coins_id = 'b24b873f-d949-436e-9902-7ff712f7513d'
    flixter_id = 'f8751513-67f1-4273-8e4e-73b1e685e83d'

    if id == clash_of_titans_offer_id
      # Only show offer in TapFish:
      return true unless publisher_app.id == tap_fish_id || publisher_app.id == tap_fish_coins_id

      # Only show offer if user has recently run flixter:
      return true if !device.has_app?(flixter_id) || device.last_run_time(flixter_id) < (Time.zone.now - 1.days)
    end
    false
  end

  def publisher_whitelist_reject?(publisher_app)
    publisher_app_whitelist.present? && !get_publisher_app_whitelist.include?(publisher_app.id)
  end

  def currency_whitelist_reject?(currency)
    currency.use_whitelist? && !currency.get_offer_whitelist.include?(id)
  end

  def minimum_bid_reject?(currency, type)
    min_bid = case type
    when Offer::DEFAULT_OFFER_TYPE
      currency.minimum_offerwall_bid
    when Offer::FEATURED_OFFER_TYPE, Offer::FEATURED_BACKFILLED_OFFER_TYPE, Offer::NON_REWARDED_FEATURED_OFFER_TYPE, Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE
      currency.minimum_featured_bid
    when Offer::DISPLAY_OFFER_TYPE, Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      currency.minimum_display_bid
    end
    min_bid.present? && bid < min_bid
  end

  def jailbroken_reject?(device)
    is_paid? && device.is_jailbroken?
  end

  def direct_pay_reject?(direct_pay_providers)
    direct_pay? && !direct_pay_providers.include?(direct_pay)
  end

  def action_app_reject?(device)
    item_type == "ActionOffer" && third_party_data.present? && !device.has_app?(third_party_data)
  end

  def min_os_version_reject?(os_version)
    return false if min_os_version.blank?
    return true if os_version.blank?

    !os_version.version_greater_than_or_equal_to?(min_os_version)
  end

  def screen_layout_sizes_reject?(screen_layout_size)
    return false if screen_layout_sizes.blank? || screen_layout_sizes == '[]'
    return true if screen_layout_size.blank?

    !get_screen_layout_sizes.include?(screen_layout_size)
  end

  def hide_rewarded_app_installs_reject?(hide_rewarded_app_installs)
    hide_rewarded_app_installs && rewarded? && item_type != 'GenericOffer' && item_type != 'VideoOffer'
  end

  def cookie_tracking_reject?(publisher_app, library_version, source)
    cookie_tracking? && source != 'tj_games' && publisher_app.platform == 'iphone' && !library_version.version_greater_than_or_equal_to?('8.0.3')
  end

  def video_offers_reject?(video_offer_ids, type)
    return false if type == Offer::VIDEO_OFFER_TYPE
    item_type == 'VideoOffer' && !video_offer_ids.include?(id)
  end

  TAPJOY_GAMES_RETARGETED_OFFERS = ['2107dd6a-a8b7-4e31-a52b-57a1a74ddbc1', '12b7ea33-8fde-4297-bae9-b7cb444897dc']
  def tapjoy_games_retargeting_reject?(device)
    TAPJOY_GAMES_RETARGETED_OFFERS.include?(item_id) && !device.has_app?(TAPJOY_GAMES_REGISTRATION_OFFER_ID)
  end
end
