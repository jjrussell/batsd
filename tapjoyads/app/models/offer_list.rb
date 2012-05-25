class OfferList
  PROMOTED_INVENTORY_SIZE = 3
  DEEPLINK_POSITION = 3  #zero-based index of where to include a Deeplink offer in the offer list

  attr_reader :offers

  def initialize(options = {})
    @publisher_app              = options.delete(:publisher_app)
    @device                     = options.delete(:device)
    @currency                   = options.delete(:currency)
    @device_type                = options.delete(:device_type)
    @geoip_data                 = options.delete(:geoip_data)              { {} }
    @app_version                = options.delete(:app_version)
    @direct_pay_providers       = options.delete(:direct_pay_providers)    { [] }
    @type                       = options.delete(:type) || Offer::DEFAULT_OFFER_TYPE
    @library_version            = options.delete(:library_version) || ''
    @os_version                 = options.delete(:os_version)
    @screen_layout_size         = options.delete(:screen_layout_size)
    @source                     = options.delete(:source)
    @exp                        = options.delete(:exp)
    @include_rating_offer       = options.delete(:include_rating_offer) { false }
    @platform_name              = options.delete(:platform_name)
    @video_offer_ids            = options.delete(:video_offer_ids) { [] }
    @all_videos                 = options.delete(:all_videos) { false }
    @mobile_carrier_code        = options.delete(:mobile_carrier_code)
    udid                        = options.delete(:udid)
    currency_id                 = options.delete(:currency_id)

    @currency ||= Currency.find_in_cache(currency_id) if currency_id.present?
    @publisher_app ||= App.find_in_cache(@currency.app_id) if @currency.present?

    @hide_rewarded_app_installs = @currency ? @currency.hide_rewarded_app_installs_for_version?(@app_version, @source) : false
    @normalized_device_type     = Device.normalize_device_type(@device_type)

    if @publisher_app
      @platform_name            = @publisher_app.platform_name
      @normalized_device_type ||=
        case @publisher_app.platform
        when 'android', 'windows'
          @publisher_app.platform
        else
          'itouch'
        end
    end

    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    if @hide_rewarded_app_installs
      @type = case @type
      when Offer::DEFAULT_OFFER_TYPE
        (@currency && !@currency.rewarded?) ? Offer::NON_REWARDED_BACKFILLED_OFFER_TYPE : @type
      when Offer::FEATURED_OFFER_TYPE
        Offer::NON_REWARDED_FEATURED_OFFER_TYPE
      when Offer::FEATURED_BACKFILLED_OFFER_TYPE
        Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE
      when Offer::DISPLAY_OFFER_TYPE
        Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      else
        @type
      end
    end

    @device ||= Device.new(:key => udid) if udid.present?
    if (@device && (@device.opted_out? || @device.banned?)) || (@currency && !@currency.tapjoy_enabled?)
      @offers = []
    else
      @offers = RailsCache.get_and_put("offers.#{@type}.#{@platform_name}.#{@hide_rewarded_app_installs}.#{@normalized_device_type}") do
        OfferCacher.get_unsorted_offers_prerejected(@type, @platform_name, @hide_rewarded_app_installs, @normalized_device_type)
      end.value
    end

    if @currency
      promoted_offers = []
      if @currency.get_promoted_offers.present? || @currency.partner_get_promoted_offers.present?
        @offers.each do |o|
          promoted_offers.push(o.id) if can_be_promoted?(o)
        end
        promoted_offers = promoted_offers.shuffle.slice(0, PROMOTED_INVENTORY_SIZE)
      end

      @offers.each do |o|
        o.postcache_rank_score(@currency, @source, promoted_offers.include?(o.id))
      end
    end
  end

  def weighted_rand
    offers = @offers.clone
    while offers.any?
      weight_scale = 1 - offers.map(&:rank_score).min
      weights = offers.collect { |o| o.rank_score + weight_scale }
      offer = offers.weighted_rand(weights)
      return offer if offer.nil?
      if postcache_reject?(offer)
        offers.delete(offer)
      else
        return offer
      end
    end
  end

def get_offers(start, max_offers)
    return [ [], 0 ] if @device && (@device.opted_out? || @device.banned?)

    all_offers = augmented_offer_list
    returned_offers = []
    found_offer_item_ids = Set.new
    offers_to_find = start + max_offers
    found_offers = 0

    all_offers.each_with_index do |offer, i|
      return [ returned_offers, all_offers.length - i ] if found_offers >= offers_to_find

      unless postcache_reject?(offer) || found_offer_item_ids.include?(offer.item_id)
        returned_offers << offer if found_offers >= start
        found_offer_item_ids << offer.item_id
        found_offers += 1
      end
    end

    [ returned_offers, 0 ]
  end

  def sorted_offers_with_rejections(currency_group_id)
    @offers.each do |offer|
      class << offer; attr_accessor :rejections; end
      offer.rejections = rejections_for(offer)
    end
    @offers.sort_by { |offer| -offer.precache_rank_score_for(currency_group_id) }
  end

  private

  def augmented_offer_list
    all_offers = []

    if @include_rating_offer && @publisher_app.enabled_rating_offer_id.present?
      rate_app_offer = Offer.find_in_cache(enabled_rating_offer_id) #BUG: should be @publisher_app.enabled_rating_offer_id
      if rate_app_offer.present? && rate_app_offer.accepting_clicks? && !postcache_reject?(rate_app_offer)
        all_offers << rate_app_offer
      end
    end

    all_offers = all_offers + @offers.sort { |a,b| b.rank_score <=> a.rank_score }

    if @currency && @currency.rewarded? && @currency.enabled_deeplink_offer_id.present? && @source == 'offerwall' && @normalized_device_type != 'android'
      deeplink_offer = Offer.find_in_cache(@currency.enabled_deeplink_offer_id)
      if deeplink_offer.present? && deeplink_offer.accepting_clicks? && !postcache_reject?(deeplink_offer)
        all_offers.insert(DEEPLINK_POSITION, deeplink_offer)
      end
    end

    all_offers
  end

  def postcache_reject?(offer)
    offer.postcache_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version,
      @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size,
      @video_offer_ids, @source, @all_videos, @mobile_carrier_code)
  end

  def can_be_promoted?(offer)
    (@currency.get_promoted_offers.include?(offer.id) || @currency.partner_get_promoted_offers.include?(offer.id)) & !postcache_reject?(offer)
  end

  def rejections_for(offer)
    offer.postcache_rejections(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version,
      @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size,
      @video_offer_ids, @source, @all_videos, @mobile_carrier_code)
  end
end
