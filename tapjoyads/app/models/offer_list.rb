class OfferList
  PROMOTED_INVENTORY_SIZE = 3
  DEEPLINK_POSITION = 3  #zero-based index of where to include a Deeplink offer in the offer list

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
    @platform_name              = options.delete(:platform_name)
    @video_offer_ids            = options.delete(:video_offer_ids) { [] }
    @all_videos                 = options.delete(:all_videos) { false }
    @mobile_carrier_code        = options.delete(:mobile_carrier_code)
    udid                        = options.delete(:udid)
    currency_id                 = options.delete(:currency_id)
    @app_store_name             = AppStore::SDK_STORE_NAMES[options.delete(:store_name)]
    @algorithm                  = options.delete(:algorithm)
    @algorithm_options          = options.delete(:algorithm_options)

    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    @algorithm_options ||= {}

    @currency ||= Currency.find_in_cache(currency_id) if currency_id.present?
    @publisher_app ||= App.find_in_cache(@currency.app_id) if @currency.present?

    @hide_rewarded_app_installs = @currency.present? && @currency.hide_rewarded_app_installs? && @source != 'tj_games' && @source != 'tj_display'
    @normalized_device_type     = Device.normalize_device_type(@device_type)

    @store_whitelist = Set.new

    if @publisher_app
      @platform_name            = @publisher_app.platform_name
      @normalized_device_type ||=
        case @publisher_app.platform
        when 'android', 'windows'
          @publisher_app.platform
        else
          'itouch'
        end

      @app_store_name ||= App::PLATFORM_DETAILS[@publisher_app.platform][:default_store_name]
      @store_whitelist << @app_store_name if AppStore.find(@app_store_name).exclusive?
    end

    if @currency && !@currency.rewarded?
      @type = case @type
      when Offer::DEFAULT_OFFER_TYPE
        Offer::NON_REWARDED_BACKFILLED_OFFER_TYPE
      when Offer::FEATURED_OFFER_TYPE
        Offer::NON_REWARDED_FEATURED_OFFER_TYPE
      when Offer::FEATURED_BACKFILLED_OFFER_TYPE
        Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE
      when Offer::DISPLAY_OFFER_TYPE
        Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      else
        @type
      end
    elsif @currency && @currency.hide_rewarded_app_installs? && @type == Offer::DISPLAY_OFFER_TYPE
      @type = Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
    end

    @device ||= Device.new(:key => udid) if udid.present?

    # TODO: Make promoted offers work with optimized offers.
    # if @currency
    #   promoted_offers = []
    #   if @currency.get_promoted_offers.present? || @currency.partner_get_promoted_offers.present?
    #     @offers.each do |o|
    #       promoted_offers.push(o.id) if can_be_promoted?(o)
    #     end
    #     promoted_offers = promoted_offers.shuffle.slice(0, PROMOTED_INVENTORY_SIZE)
    #   end
    # end

    @store_whitelist.merge(@currency.get_store_whitelist) if @currency && @currency.get_store_whitelist.present?
  end

  def weighted_rand
    selectable_offers = offers.clone
    while selectable_offers.any?
      weight_scale = 1 - selectable_offers.map(&:rank_score).min
      weights = selectable_offers.collect { |o| o.rank_score + weight_scale }
      offer = selectable_offers.weighted_rand(weights)
      return offer if offer.nil?
      if postcache_reject?(offer)
        selectable_offers.delete(offer)
      else
        return offer
      end
    end
  end

  def get_offers(start, max_offers)
    return [ [], 0 ] if @device && !@device.can_view_offers?

    returned_offers = []
    found_offer_item_ids = Set.new
    offers_to_find = start + max_offers
    found_offers = 0
    offers_left = 0

    unless @algorithm.blank?
      # TODO: dry this up.
      optimized_offers.each_with_index do |offer, i|
        if found_offers >= offers_to_find
          offers_left = optimized_offers.length - i
          break
        end

        unless optimization_reject?(offer) || found_offer_item_ids.include?(offer.item_id)
          returned_offers << offer if found_offers >= start
          found_offer_item_ids << offer.item_id
          found_offers += 1
        end
      end
    end

    default_offers.each_with_index do |offer, i|
      if found_offers >= offers_to_find
        offers_left += default_offers.length - i
        break
      end

      unless postcache_reject?(offer) || found_offer_item_ids.include?(offer.item_id)
        returned_offers << offer if found_offers >= start
        found_offer_item_ids << offer.item_id
        found_offers += 1
      end
    end

    if DEEPLINK_POSITION >= start && @currency && @currency.rewarded? && @currency.external_publisher? && @currency.enabled_deeplink_offer_id.present? && @source == 'offerwall' && @normalized_device_type != 'android'
      deeplink_offer = Offer.find_in_cache(@currency.enabled_deeplink_offer_id)
      if deeplink_offer.present? && deeplink_offer.accepting_clicks? && !postcache_reject?(deeplink_offer) && !found_offer_item_ids.include?(deeplink_offer.item_id)
        position = [ DEEPLINK_POSITION, returned_offers.length ].min
        deeplink_offer.name = I18n.t('text.offerwall.promo_link', :default => "Check out more ways to enjoy the apps you love at Tapjoy.com!")
        returned_offers.insert(position, deeplink_offer)
      end
    end

    [ returned_offers, offers_left ]
  end

  def sorted_offers_with_rejections(currency_group_id)
    add_rejections!(offers)
    offers
  end

  def sorted_optimized_offers_with_rejections
    add_rejections!(optimized_offers)
    optimized_offers
  end

  def optimized_offers
    @optmized_offers ||= get_optimized_offers
  end

  def default_offers
    @default_offers ||= get_default_offers
  end

  alias_method :offers, :default_offers

  private

  def get_optimized_offers

    country = @algorithm_options[:skip_country] ? nil : @geoip_data[:primary_country]
    currency_id = @currency.present? ? @currency.id : nil
    currency_id = nil if @algorithm_options[:skip_currency]

    RailsCache.get_and_put("optimized_offers.#{@algorithm}.#{@source}.#{@platform_name}.#{country}.#{currency_id}.#{@normalized_device_type}") do
      OptimizedOfferList.get_offer_list(
        :algorithm => @algorithm,
        :source => @source,
        :platform => @platform_name,
        :country => country,
        :currency_id => currency_id,
        :device_type => @normalized_device_type
      )
    end.value
  end

  def get_default_offers
    return [] if (@device && !@device.can_view_offers?) || (@currency && !@currency.tapjoy_enabled?)

    default_offers = RailsCache.get_and_put("offers.#{@type}.#{@platform_name}.#{@hide_rewarded_app_installs}.#{@normalized_device_type}") do
      OfferCacher.get_offers_prerejected(@type, @platform_name, @hide_rewarded_app_installs, @normalized_device_type)
    end.value

    default_offers
  end

  def optimization_reject?(offer)
    postcache_reject?(offer) || offer.hide_rewarded_app_installs_reject?(@hide_rewarded_app_installs)
  end

  def postcache_reject?(offer)
    offer.postcache_reject?(@publisher_app, @device, @currency, @normalized_device_type, @geoip_data, @app_version,
      @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size,
      @video_offer_ids, @source, @all_videos, @mobile_carrier_code, @store_whitelist,  @app_store_name)
  end

  def can_be_promoted?(offer)
    (@currency.get_promoted_offers.include?(offer.id) || @currency.partner_get_promoted_offers.include?(offer.id)) & !postcache_reject?(offer)
  end

  def rejections_for(offer)
    offer.postcache_rejections(@publisher_app, @device, @currency, @normalized_device_type, @geoip_data, @app_version,
      @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size,
      @video_offer_ids, @source, @all_videos, @mobile_carrier_code, @store_whitelist, @app_store_name)
  end

  def add_rejections!(offers)
    offers.each do |offer|
      class << offer; attr_accessor :rejections; end
      offer.rejections = rejections_for(offer)
    end
  end
end
