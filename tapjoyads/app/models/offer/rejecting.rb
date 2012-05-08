module Offer::Rejecting

  ALREADY_COMPLETE_IDS = {
    # Tap Farm
    [ '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424' ] => [ '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424', 'bad4b0ae-8458-42ba-97ba-13b302827234', '403014c2-9a1b-4c1d-8903-5a41aa09be0e' ],
    # Tap Store
    [ 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91' ] => [ 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91', 'a994587c-390c-4295-a6b6-dd27713030cb', '6703401f-1cb2-42ec-a6a4-4c191f8adc27' ],
    # Clubworld
    [ '3885c044-9c8e-41d4-b136-c877915dda91' ] => [ '3885c044-9c8e-41d4-b136-c877915dda91', 'a3980ac5-7d33-43bc-8ba1-e4598c7ed279' ],
    # Groupon iOS Apps
    [ '7f44c068-6fa1-482c-b2d2-770edcf8f83d', '192e6d0b-cc2f-44c2-957c-9481e3c223a0', '05d8d649-766a-40d2-9fc3-1009307ff966', 'a07cfeda-8f35-4490-99ea-f75ee7463fa4' ] => [ '7f44c068-6fa1-482c-b2d2-770edcf8f83d', '192e6d0b-cc2f-44c2-957c-9481e3c223a0', '05d8d649-766a-40d2-9fc3-1009307ff966', 'a07cfeda-8f35-4490-99ea-f75ee7463fa4' ],
    # Groupon iOS ActionOffers
    [ 'a13bd597-183a-41ce-a6e1-48797e61be9d', 'aa136cec-6241-4cb9-b790-e8ed1532f64e', '43a65418-3863-42b5-80fc-ea4b02828db2' ] => [ 'a13bd597-183a-41ce-a6e1-48797e61be9d', 'aa136cec-6241-4cb9-b790-e8ed1532f64e', '43a65418-3863-42b5-80fc-ea4b02828db2' ],
    # Groupon Android Apps
    [ '3368863b-0c69-4a54-8a14-2ec809140d8f', 'bbadbb72-4f96-49e3-90b8-fb45a82b195e' ] => [ '3368863b-0c69-4a54-8a14-2ec809140d8f', 'bbadbb72-4f96-49e3-90b8-fb45a82b195e' ],
    # My Town 2
    [ 'cab56716-8e27-4a4c-8477-457e1d311209', '069eafb8-a9b8-4293-8d2a-e9d9ed659ac8' ] => [ 'cab56716-8e27-4a4c-8477-457e1d311209', '069eafb8-a9b8-4293-8d2a-e9d9ed659ac8' ],
    # Snoopy's Street Fair
    [ '99d4a403-38a8-41e3-b7a2-5778acb968ef', 'b22f3ef8-947f-4605-a5bc-a83609af5ab7' ] => [ '99d4a403-38a8-41e3-b7a2-5778acb968ef', 'b22f3ef8-947f-4605-a5bc-a83609af5ab7' ],
    # Zombie Lane
    [ 'd299fb80-29f6-48a3-8957-bbd8a20acdc9', 'eca4615a-7439-486c-b5c3-efafe3ec69a6' ] => [ 'd299fb80-29f6-48a3-8957-bbd8a20acdc9', 'eca4615a-7439-486c-b5c3-efafe3ec69a6' ],
    # iTriage
    [ '7f398870-b1da-478f-adfb-82d22d25c13d', '6f7d9238-be52-46e9-902b-5ad038ddb7eb' ] => [ '7f398870-b1da-478f-adfb-82d22d25c13d', '6f7d9238-be52-46e9-902b-5ad038ddb7eb' ],
    # Intuit GoPayment
    [ 'e8cca05a-0ec0-41fd-9820-24e24db6eec4', 'b1a1b737-bc9d-4a0b-9587-a887d22ae356' ] => [ 'e8cca05a-0ec0-41fd-9820-24e24db6eec4', 'b1a1b737-bc9d-4a0b-9587-a887d22ae356' ],
    # Hotels.com
    [ '6b714133-2358-4918-842d-f266abe6b7b5', 'eaa1cfc9-3499-49ce-8f03-092bcc0ce77a' ] => [ '6b714133-2358-4918-842d-f266abe6b7b5', 'eaa1cfc9-3499-49ce-8f03-092bcc0ce77a' ],
    # Trulia Real Estate
    [ 'afde4da8-3943-44fd-a901-08be5470eaa4', '2ff9ad4e-58a2-417b-9333-d65835b71049' ] => [ 'afde4da8-3943-44fd-a901-08be5470eaa4', '2ff9ad4e-58a2-417b-9333-d65835b71049' ],
    # Social Girl
    [ '7df94075-16c9-4c6a-a170-50e1e8fc9991', '3712bd73-eda2-4ca9-934a-3465cf38ef35' ] => [ '7df94075-16c9-4c6a-a170-50e1e8fc9991', '3712bd73-eda2-4ca9-934a-3465cf38ef35' ],
    # Top Girl
    [ 'c7b2a54e-8faf-4959-86ab-e862473c9dd4', '9f47822c-2183-4969-98b1-ce64430e4e58' ] => [ 'c7b2a54e-8faf-4959-86ab-e862473c9dd4', '9f47822c-2183-4969-98b1-ce64430e4e58' ],
    # Saving Star
    [ 'c2ef96ba-5c6b-4479-bffa-9b1beca08f1b', '1d63a4fa-82ed-4442-955c-ef0d75978fad', '0ba2a533-d26d-4953-aa3e-fd01187e30e1' ] => [ 'c2ef96ba-5c6b-4479-bffa-9b1beca08f1b', '1d63a4fa-82ed-4442-955c-ef0d75978fad', '0ba2a533-d26d-4953-aa3e-fd01187e30e1' ],
    # Flirtomatic iOS
    [ 'bb26407e-6713-4b67-893d-4b47242f1ce0', '23fed671-4558-4c2e-8ceb-dcb41399c5d7',
      '398a71ee-5157-4975-aabb-f7fa5a48ed7f', 'd5769336-acd4-4d25-9483-f84512247b7a',
      'b8dfb746-ceba-44af-814b-d04231afcc11' ] => [ 'bb26407e-6713-4b67-893d-4b47242f1ce0',
      '23fed671-4558-4c2e-8ceb-dcb41399c5d7', '398a71ee-5157-4975-aabb-f7fa5a48ed7f',
      'd5769336-acd4-4d25-9483-f84512247b7a', 'b8dfb746-ceba-44af-814b-d04231afcc11' ],
    # Credit Sesame
    [ 'e13d1e07-9770-4d71-a9ba-fa42fd8df519', 'a3abde4d-7eff-49c7-8079-85d2c5238e88' ] => [ 'e13d1e07-9770-4d71-a9ba-fa42fd8df519', 'a3abde4d-7eff-49c7-8079-85d2c5238e88' ],
    # Play Up
    [ 'de54dbd2-71ff-405e-86f6-f680dcffe8d7', '02c569fc-4a3b-4807-897d-70fad43ae64a' ] => [ 'de54dbd2-71ff-405e-86f6-f680dcffe8d7', '02c569fc-4a3b-4807-897d-70fad43ae64a' ],
    # Priceline
    [ 'b64dba85-9cf9-4e14-b991-f3b7574880c7', '70d3de82-3062-4f19-8864-e453d8b9ee35' ] => [ 'b64dba85-9cf9-4e14-b991-f3b7574880c7', '70d3de82-3062-4f19-8864-e453d8b9ee35' ],
    # Gamefly
    [ 'ac845f34-6631-45f4-8d7e-8d9d981c05b4', '0c785af7-57b8-4efe-9112-44c7194f5a94' ] => [ 'ac845f34-6631-45f4-8d7e-8d9d981c05b4', '0c785af7-57b8-4efe-9112-44c7194f5a94' ],
    # Zillow
    [ '11bf4c4e-0a00-4536-b029-cf455f4976c0', 'd1d5ec4c-ec7d-490b-a1e0-76af0967de53' ] => [ '11bf4c4e-0a00-4536-b029-cf455f4976c0', 'd1d5ec4c-ec7d-490b-a1e0-76af0967de53' ],
    # Mobile Xpression
    [ '49cbc1ae-8f04-4220-b0b8-d23a1559a560', '9007b2c0-6e26-46df-8950-ade2250e6167' ] => [ '49cbc1ae-8f04-4220-b0b8-d23a1559a560', '9007b2c0-6e26-46df-8950-ade2250e6167' ],
  }

  TAPJOY_GAMES_RETARGETED_OFFERS = ['2107dd6a-a8b7-4e31-a52b-57a1a74ddbc1', '12b7ea33-8fde-4297-bae9-b7cb444897dc', '8183ce57-8ee4-46c0-ab50-4b10862e2a27']

  def postcache_rejections(publisher_app, device, currency, device_type, geoip_data, app_version,
      direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version,
      screen_layout_size, video_offer_ids, source, all_videos, mobile_carrier_code)
    reasons = []
    reject_functions = [
      { :method => :geoip_reject?, :parameters => [geoip_data], :reason => 'geoip'.humanize },
      { :method => :already_complete?, :parameters => [device, app_version], :reason => 'already_complete'.humanize },
      { :method => :selective_opt_out_reject?, :parameters => [device], :reason => 'selective_opt_out'.humanize },
      { :method => :flixter_reject?, :parameters => [publisher_app, device], :reason => 'flixter'.humanize },
      { :method => :minimum_bid_reject?, :parameters => [currency, type], :reason => 'minimum_bid'.humanize },
      { :method => :jailbroken_reject?, :parameters => [device], :reason => 'jailbroken'.humanize },
      { :method => :direct_pay_reject?, :parameters => [direct_pay_providers], :reason => 'direct_pay'.humanize },
      { :method => :action_app_reject?, :parameters => [device], :reason => 'action_app'.humanize },
      { :method => :min_os_version_reject?, :parameters => [os_version], :reason => 'min_os_version'.humanize },
      { :method => :cookie_tracking_reject?, :parameters => [publisher_app, library_version, source], :reason => 'cookie_tracking'.humanize },
      { :method => :screen_layout_sizes_reject?, :parameters => [screen_layout_size], :reason => 'screen_layout_sizes'.humanize },
      { :method => :offer_is_the_publisher?, :parameters => [currency], :reason => 'offer_is_the_publisher'.humanize },
      { :method => :offer_is_blacklisted_by_currency?, :parameters => [currency], :reason => 'offer_is_blacklisted_by_currency'.humanize },
      { :method => :partner_is_blacklisted_by_currency?, :parameters => [currency], :reason => 'partner_is_blacklisted_by_currency'.humanize },
      { :method => :currency_only_allows_free_offers?, :parameters => [currency], :reason => 'currency_only_allows_free_offers'.humanize },
      { :method => :self_promote_reject?, :parameters => [publisher_app], :reason => 'self_promote_only'.humanize },
      { :method => :age_rating_reject?, :parameters => [ currency && currency.max_age_rating], :reason => 'age_rating'.humanize },
      { :method => :publisher_whitelist_reject?, :parameters => [publisher_app], :reason => 'publisher_whitelist'.humanize },
      { :method => :currency_whitelist_reject?, :parameters => [currency], :reason => 'currency_whitelist'.humanize },
      { :method => :frequency_capping_reject?, :parameters => [device], :reason => 'frequency_capping'.humanize },
      { :method => :tapjoy_games_retargeting_reject?, :parameters => [device], :reason => 'tapjoy_games_retargeting'.humanize },
      { :method => :source_reject?, :parameters => [source], :reason => 'source'.humanize },
      { :method => :non_rewarded_offerwall_rewarded_reject?, :parameters => [currency], :reason => 'non_rewarded_offerwall_rewarded'.humanize },
      { :method => :carriers_reject?, :parameters => [mobile_carrier_code], :reason => 'carriers'.humanize },
    ]
    reject_functions.each do |function_hash|
      reasons << function_hash[:reason] if send(function_hash[:method], *function_hash[:parameters])
    end
    reasons
  end

  def postcache_reject?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version, screen_layout_size, video_offer_ids, source, all_videos, mobile_carrier_code)
    geoip_reject?(geoip_data) ||
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
    offer_is_the_publisher?(currency) ||
    offer_is_blacklisted_by_currency?(currency) ||
    partner_is_blacklisted_by_currency?(currency) ||
    currency_only_allows_free_offers?(currency) ||
    self_promote_reject?(publisher_app) ||
    age_rating_reject?(currency.max_age_rating) ||
    publisher_whitelist_reject?(publisher_app) ||
    currency_whitelist_reject?(currency) ||
    video_offers_reject?(video_offer_ids, type, all_videos) ||
    frequency_capping_reject?(device) ||
    tapjoy_games_retargeting_reject?(device) ||
    source_reject?(source) ||
    non_rewarded_offerwall_rewarded_reject?(currency) ||
    carriers_reject?(mobile_carrier_code) ||
    sdkless_reject?(library_version)
  end

  def precache_reject?(platform_name, hide_rewarded_app_installs, normalized_device_type)
    app_platform_mismatch?(platform_name) || hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) || device_platform_mismatch?(normalized_device_type)
  end

  def frequency_capping_reject?(device)
    return false unless multi_complete? && interval != Offer::FREQUENCIES_CAPPING_INTERVAL['none'] && device

    device.has_app?(item_id) && (device.last_run_time(item_id) + interval > Time.zone.now)
  end

  def recommendation_reject?(device, device_type, geoip_data, os_version)
    recommendable_types_reject? ||
      device_platform_mismatch?(device_type) ||
      geoip_reject?(geoip_data) ||
      already_complete?(device) ||
      min_os_version_reject?(os_version) ||
      age_rating_reject?(3) # reject 17+ apps
  end

  def geoip_reject?(geoip_data)
    return true if get_countries.present? && !get_countries.include?(geoip_data[:primary_country])
    return true if countries_blacklist.include?(geoip_data[:primary_country])
    return true if get_regions.present? && !get_regions.include?(geoip_data[:region])
    return true if get_dma_codes.present? && !get_dma_codes.include?(geoip_data[:dma_code])
    return true if get_cities.present? && !get_cities.include?(geoip_data[:city])
    false
  end

  private

  def offer_is_the_publisher?(currency)
    return false unless currency
    item_id == currency.app_id
  end

  def offer_is_blacklisted_by_currency?(currency)
    return false unless currency
    currency.get_disabled_offer_ids.include?(item_id) || currency.get_disabled_offer_ids.include?(id)
  end

  def partner_is_blacklisted_by_currency?(currency)
    return false unless currency
    currency.get_disabled_partner_ids.include?(partner_id)
  end

  def currency_only_allows_free_offers?(currency)
    return false unless currency
    currency.only_free_offers? && is_paid?
  end

  def self_promote_reject?(publisher_app)
    return false unless publisher_app
    self_promote_only? && partner_id != publisher_app.partner_id
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

  def age_rating_reject?(max_age_rating)
    return false unless max_age_rating && age_rating

    max_age_rating < age_rating
  end

  def already_complete?(device, app_version = nil)
    return false if multi_complete? || device.nil?

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
    device && device.opt_out_offer_types.include?(item_type)
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
    publisher_app && publisher_app_whitelist.present? && !get_publisher_app_whitelist.include?(publisher_app.id)
  end

  def currency_whitelist_reject?(currency)
    currency && currency.use_whitelist? && !currency.get_offer_whitelist.include?(id)
  end

  def minimum_bid_reject?(currency, type)
    return false unless currency
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
    is_paid? && device && device.is_jailbroken?
  end

  def direct_pay_reject?(direct_pay_providers)
    direct_pay? && !direct_pay_providers.include?(direct_pay)
  end

  def action_app_reject?(device)
    item_type == "ActionOffer" && third_party_data.present? && device && !device.has_app?(third_party_data)
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
    publisher_app && cookie_tracking? && source != 'tj_games' && publisher_app.platform == 'iphone' && !library_version.version_greater_than_or_equal_to?('8.0.3')
  end

  def video_offers_reject?(video_offer_ids, type, all_videos)
    return false if type == Offer::VIDEO_OFFER_TYPE || all_videos

    item_type == 'VideoOffer' && !video_offer_ids.include?(id)
  end

  def tapjoy_games_retargeting_reject?(device)
    TAPJOY_GAMES_RETARGETED_OFFERS.include?(item_id) && device && !device.has_app?(TAPJOY_GAMES_REGISTRATION_OFFER_ID)
  end

  def source_reject?(source)
    get_approved_sources.any? && !get_approved_sources.include?(source)
  end

  def non_rewarded_offerwall_rewarded_reject?(currency)
    currency && !currency.rewarded? && rewarded? && item_type != 'App'
  end

  def recommendable_types_reject?
    item_type != 'App'
  end

  def carriers_reject?(mobile_carrier_code)
    get_carriers.present? && !get_carriers.include?(Carriers::MCC_MNC_TO_CARRIER_NAME[mobile_carrier_code])
  end

  def sdkless_reject?(library_version)
    sdkless? && !library_version.to_s.version_greater_than_or_equal_to?(SDKLESS_MIN_LIBRARY_VERSION)
  end

end
