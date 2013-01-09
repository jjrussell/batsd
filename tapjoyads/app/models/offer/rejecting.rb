module Offer::Rejecting

  NON_LIMITED_CURRENCY_IDS = Set.new([
    'cc660353-0c63-4c27-891c-bffa0de3c42e',
    '84c7718d-ed28-4848-8532-09302ac85940',
    '59d168fa-a9fe-4883-a582-1cc842668a36',
    '40f9ee86-5759-4655-96dd-3cd4bbab1853',])

  TAPJOY_GAMES_RETARGETED_OFFERS = ['2107dd6a-a8b7-4e31-a52b-57a1a74ddbc1', '12b7ea33-8fde-4297-bae9-b7cb444897dc', '8183ce57-8ee4-46c0-ab50-4b10862e2a27']
  TAPJOY_GAMES_OFFERS = [ TAPJOY_GAMES_REGISTRATION_OFFER_ID, LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID]

  MINISCULE_REWARD_THRESHOLD = 0.25

  def postcache_rejections(publisher_app, device, currency, device_type, geoip_data, app_version,
      direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version,
      video_offer_ids, source, all_videos, store_whitelist, store_name)
    reject_functions = [
      { :method => :geoip_reject?, :parameters => [geoip_data], :reason => 'geoip' },
      { :method => :already_complete?, :parameters => [device, app_version], :reason => 'already_complete' },
      { :method => :prerequisites_not_complete?, :parameters => [device], :reason => 'prerequisites_not_complete' },
      { :method => :selective_opt_out_reject?, :parameters => [device], :reason => 'selective_opt_out' },
      { :method => :flixter_reject?, :parameters => [publisher_app, device], :reason => 'flixter' },
      { :method => :minimum_bid_reject?, :parameters => [currency, type], :reason => 'minimum_bid' },
      { :method => :jailbroken_reject?, :parameters => [device], :reason => 'jailbroken' },
      { :method => :direct_pay_reject?, :parameters => [direct_pay_providers], :reason => 'direct_pay' },
      { :method => :min_os_version_reject?, :parameters => [os_version], :reason => 'min_os_version' },
      { :method => :cookie_tracking_reject?, :parameters => [publisher_app, library_version, source], :reason => 'cookie_tracking' },
      { :method => :screen_layout_sizes_reject?, :parameters => [device], :reason => 'screen_layout_sizes' },
      { :method => :offer_is_the_publisher?, :parameters => [currency], :reason => 'offer_is_the_publisher' },
      { :method => :offer_is_blacklisted_by_currency?, :parameters => [currency], :reason => 'offer_is_blacklisted_by_currency' },
      { :method => :partner_is_blacklisted_by_currency?, :parameters => [currency], :reason => 'partner_is_blacklisted_by_currency' },
      { :method => :currency_only_allows_free_offers?, :parameters => [currency], :reason => 'currency_only_allows_free_offers' },
      { :method => :self_promote_reject?, :parameters => [publisher_app], :reason => 'self_promote_only' },
      { :method => :age_rating_reject?, :parameters => [ currency && currency.max_age_rating], :reason => 'age_rating' },
      { :method => :publisher_whitelist_reject?, :parameters => [publisher_app], :reason => 'publisher_whitelist' },
      { :method => :currency_whitelist_reject?, :parameters => [currency], :reason => 'currency_whitelist' },
      { :method => :frequency_capping_reject?, :parameters => [device], :reason => 'frequency_capping' },
      { :method => :tapjoy_games_retargeting_reject?, :parameters => [device], :reason => 'tapjoy_games_retargeting' },
      { :method => :source_reject?, :parameters => [source], :reason => 'source' },
      { :method => :non_rewarded_offerwall_rewarded_reject?, :parameters => [currency], :reason => 'non_rewarded_offerwall_rewarded' },
      { :method => :carriers_reject?, :parameters => [device], :reason => 'carriers' },
      { :method => :app_store_reject?, :parameters => [store_whitelist], :reason => 'app_store' },
      { :method => :distribution_reject?, :parameters => [store_name], :reason => 'distribution' },
      { :method => :miniscule_reward_reject?, :parameters => currency, :reason => 'miniscule_reward'},
      { :method => :age_gating_reject?, :parameters => device, :reason => 'age_gating'},
      { :method => :has_coupon_already_pending?, :parameters => [device], :reason => 'coupon_already_requested'},
      { :method => :has_coupon_offer_expired?, :reason => 'coupon_expired'},
      { :method => :has_coupon_offer_not_started?, :reason => 'coupon_not_started'},
      { :method => :udid_required_reject?, :parameters => [device], :reason => 'udid_required'},
      { :method => :mac_address_required_reject?, :parameters => [device], :reason => 'mac_address_required'},
      { :method => :ppe_missing_prerequisite_for_ios_reject?, :parameters => [source, device_type], :reason => 'prerequisite_for_ios_required'},
      { :method => :admin_device_required_reject?, :parameters => [device], :reason => 'admin_device_required'},
      { :method => :offer_filter_reject?, :parameters => [currency], :reason => 'offer_filter_filtered'}
    ]
    reject_reasons(reject_functions)
  end

  def postcache_reject?(publisher_app, device, currency, device_type, geoip_data, app_version,
      direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version,
      video_offer_ids, source, all_videos, store_whitelist, store_name)
    geoip_reject?(geoip_data) ||
    already_complete?(device, app_version) ||
    prerequisites_not_complete?(device) ||
    selective_opt_out_reject?(device) ||
    show_rate_reject?(device, type, currency) ||
    flixter_reject?(publisher_app, device) ||
    minimum_bid_reject?(currency, type) ||
    jailbroken_reject?(device) ||
    direct_pay_reject?(direct_pay_providers) ||
    min_os_version_reject?(os_version) ||
    cookie_tracking_reject?(publisher_app, library_version, source) ||
    screen_layout_sizes_reject?(device) ||
    offer_is_the_publisher?(currency) ||
    offer_is_blacklisted_by_currency?(currency) ||
    partner_is_blacklisted_by_currency?(currency) ||
    currency_only_allows_free_offers?(currency) ||
    self_promote_reject?(publisher_app) ||
    age_rating_reject?(currency.max_age_rating) ||
    publisher_whitelist_reject?(publisher_app) ||
    currency_whitelist_reject?(currency) ||
    video_offers_reject?(video_offer_ids, type, all_videos, library_version, source) ||
    frequency_capping_reject?(device) ||
    tapjoy_games_retargeting_reject?(device) ||
    source_reject?(source) ||
    non_rewarded_offerwall_rewarded_reject?(currency) ||
    carriers_reject?(device) ||
    sdkless_reject?(library_version) ||
    recently_skipped?(device) ||
    has_insufficient_funds?(currency) ||
    rewarded_offerwall_non_rewarded_reject?(currency, source) ||
    app_store_reject?(store_whitelist) ||
    distribution_reject?(store_name) ||
    miniscule_reward_reject?(currency) ||
    age_gating_reject?(device) ||
    has_coupon_already_pending?(device) ||
    has_coupon_offer_not_started? ||
    has_coupon_offer_expired? ||
    udid_required_reject?(device) ||
    mac_address_required_reject?(device) ||
    ppe_missing_prerequisite_for_ios_reject?(source, device_type) ||
    admin_device_required_reject?(device) ||
    offer_filter_reject?(currency)
  end

  def precache_reject?(platform_name, hide_rewarded_app_installs, normalized_device_type)
    app_platform_mismatch?(platform_name) || hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) || device_platform_mismatch?(normalized_device_type)
  end

  def reject_reasons(reject_functions)
    reject_functions.select do |function_hash|
      if function_hash.keys.include?(:parameters)
        send(function_hash[:method], *function_hash[:parameters])
      else
        send(function_hash[:method])
      end
    end.map do |function_hash|
      function_hash[:reason].humanize
    end
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

  def hide_rewarded_app_installs_reject?(hide_rewarded_app_installs)
    hide_rewarded_app_installs && rewarded? && Offer::REWARDED_APP_INSTALL_OFFER_TYPES.include?(item_type)
  end

  def has_insufficient_funds?(currency)
    currency.charges?(self) && partner_balance <= 0
  end

  def has_coupon_already_pending?(device)
     has_valid_coupon?(device) && device.pending_coupons.include?(self.id)
  end

  def has_coupon_offer_not_started?
    has_valid_coupon? && self.coupon.start_date > Date.today
  end

  def has_coupon_offer_expired?
    has_valid_coupon? && self.coupon.end_date <= Date.today
  end

  def ppe_missing_prerequisite_for_ios_reject?(source, device_type)
    source != 'tj_games' && Offer::APPLE_DEVICES.include?(device_type) &&
      item_type == "ActionOffer" && prerequisite_offer_id.blank?
  end

  def offer_filter_reject?(currency)
    !Offer::IMPLICIT_OFFER_TYPES.include?(item_type) && currency && currency.offer_filter && !currency.offer_filter.split(',').include?(item_type)
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

  def admin_device_required_reject?(device)
    device && requires_admin_device? && !device.last_run_time_tester?
  end

  private

  def has_valid_coupon?(device=true)
    self.present? && device.present? && !multi_complete? && item_type == 'Coupon'
  end

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


  def age_rating_reject?(max_age_rating)
    return false unless max_age_rating && age_rating

    max_age_rating < age_rating
  end

  def already_complete?(device, app_version = nil)
    offer_complete?(self, device, app_version)
  end

  def prerequisites_not_complete?(device)
    return false if prerequisite_offer_id.blank? && get_exclusion_prerequisite_offer_ids.blank? && get_x_partner_prerequisites.blank? && get_x_partner_exclusion_prerequisites.blank?
    return true if prerequisite_offer_id.present? && !offer_complete?(Offer.find_in_cache(prerequisite_offer_id), device, nil, false)
    return true if get_x_partner_prerequisites.present? && get_x_partner_prerequisites.any?{ |id| !offer_complete?(Offer.find_in_cache(id), device, nil, false) }
    return true if get_exclusion_prerequisite_offer_ids.present? && get_exclusion_prerequisite_offer_ids.any?{ |id| offer_complete?(Offer.find_in_cache(id), device, nil, false) }
    return true if get_x_partner_exclusion_prerequisites.present? && get_x_partner_exclusion_prerequisites.any?{ |id| offer_complete?(Offer.find_in_cache(id), device, nil, false) }
    false
  end

  def offer_complete?(offer, device, app_version = nil, skip_multi_complete = true)
    return false if offer.nil? || (skip_multi_complete && offer.multi_complete?) || device.nil?

    app_id_for_device = offer.item_id
    if offer.item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(app_id_for_device, app_version)
    end

    device.has_app?(app_id_for_device)
  end

  def recently_skipped?(device)
    device.recently_skipped?(id)
  end

  def selective_opt_out_reject?(device)
    device && device.opt_out_offer_types.include?(item_type)
  end

  def show_rate_reject?(device, type, currency)
    return false if type == Offer::VIDEO_OFFER_TYPE
    return false if NON_LIMITED_CURRENCY_IDS.include?(currency.id) && show_rate > 0
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
    when Offer::DEFAULT_OFFER_TYPE, Offer::VIDEO_OFFER_TYPE
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

  def min_os_version_reject?(os_version)
    return false if min_os_version.blank?
    return true if os_version.blank?

    !os_version.version_greater_than_or_equal_to?(min_os_version)
  end

  def screen_layout_sizes_reject?(device)
    return false if screen_layout_sizes.blank? || screen_layout_sizes == '[]'
    return true if device.screen_layout_size.blank?

    !get_screen_layout_sizes.include?(device.screen_layout_size)
  end

  def cookie_tracking_reject?(publisher_app, library_version, source)
    publisher_app && cookie_tracking? && source != 'tj_games' && publisher_app.platform == 'iphone' && !library_version.version_greater_than_or_equal_to?('8.0.3')
  end

  def video_offers_reject?(video_offer_ids, type, all_videos, library_version, source)
    # reject video featured ad in old SDK
    return true if video_offer? && source == 'featured' && library_version.version_less_than?('9.0.0')

    return false if type == Offer::VIDEO_OFFER_TYPE || all_videos

    video_offer? && !video_offer_ids.include?(id)
  end

  def tapjoy_games_retargeting_reject?(device)
    has_tjm = device.present? ? device.has_app?(TAPJOY_GAMES_REGISTRATION_OFFER_ID) || device.has_app?(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID) : false
    if TAPJOY_GAMES_RETARGETED_OFFERS.include?(item_id)
      return (device && !has_tjm)
    elsif TAPJOY_GAMES_OFFERS.include?(item_id)
      return (device && has_tjm)
    end
    false
  end

  def source_reject?(source)
    get_approved_sources.any? && !get_approved_sources.include?(source)
  end

  def non_rewarded_offerwall_rewarded_reject?(currency)
    currency && !currency.rewarded? && rewarded? && item_type != 'App'
  end

  def rewarded_offerwall_non_rewarded_reject?(currency, source)
    currency && currency.rewarded? && !rewarded? && (source == 'offerwall' || source == 'tj_games')
  end

  def recommendable_types_reject?
    item_type != 'App'
  end

  def carriers_reject?(device)
    get_carriers.present? && !get_carriers.include?(Carriers::MCC_MNC_TO_CARRIER_NAME[device.try(:mobile_carrier_code)])
  end

  def sdkless_reject?(library_version)
    sdkless? && !library_version.to_library_version.sdkless_integration?
  end

  def app_store_reject?(store_whitelist)
    store_whitelist.present? && app_metadata_store_name && !store_whitelist.include?(app_metadata_store_name)
  end

  def distribution_reject?(store_name)
    return false unless store_name
    cached_item =  item_type.constantize.respond_to?(:find_in_cache) ? item_type.constantize.find_in_cache(item_id) : nil
    return cached_item.distribution_reject?(store_name) if cached_item.respond_to?('distribution_reject?')
    false
  end

  def miniscule_reward_reject?(currency)
    currency && currency.rewarded? && rewarded? &&
      currency.get_raw_reward_value(self) < MINISCULE_REWARD_THRESHOLD &&
      item_type != 'DeeplinkOffer' && !rate_filter_override
  end

  def age_gating_reject?(device)
    device && age_gate? && !Mc.distributed_get("#{Offer::MC_KEY_AGE_GATING_PREFIX}.#{device.key}.#{id}").nil?
  end

  def udid_required_reject?(device)
    device && requires_udid? && !device.id.udid?
  end

  def mac_address_required_reject?(device)
    device && requires_mac_address? && device.mac_address.blank?
  end
end
