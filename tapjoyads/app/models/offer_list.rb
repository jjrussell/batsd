class OfferList
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
    @hide_rewarded_app_installs = options.delete(:hide_rewarded_app_installs)
    @video_offer_ids            = options.delete(:video_offer_ids) { [] }
    
    @hide_rewarded_app_installs = @currency.hide_rewarded_app_installs_for_version?(@app_version, @source) if @currency
    @platform_name              = @publisher_app.platform_name if @publisher_app
    @normalized_device_type     = Device.normalize_device_type(@device_type)
    
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    if @hide_rewarded_app_installs
      @type = case @type
      when Offer::FEATURED_OFFER_TYPE
        Offer::NON_REWARDED_FEATURED_OFFER_TYPE
      when Offer::DISPLAY_OFFER_TYPE
        Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      else
        @type
      end
    end
    
    if @device && @device.opted_out?
      @offers = []
    else    
      @offers = RailsCache.get_and_put("offers.#{@type}.#{@platform_name}.#{@hide_rewarded_app_installs}.#{@normalized_device_type}") do
        OfferCacher.get_unsorted_offers_prerejected(@type, @platform_name, @hide_rewarded_app_installs, @normalized_device_type)
      end.value
    end
    
    if @currency
      @offers.each do |o|
        o.postcache_rank_score(@currency)
      end
    end
  end
  
  def weighted_rand
    offers = @offers.clone
    while offers.any?
      weight_scale = 1 - offers.last.rank_score
      weights = offers.collect { |o| o.rank_score + weight_scale }
      offer = offers.weighted_rand(weights)
      return offer if offer.nil?
      if offer.postcache_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version, @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size, @video_offer_ids)
        offers.delete(offer)
      else
        return offer
      end
    end
  end
  
  def get_offers(start, max_offers)
    return [ [], 0 ] if @device && @device.opted_out?
    @offers.sort! { |a,b| b.rank_score <=> a.rank_score }
    returned_offers = []
    offers_to_find  = start + max_offers
    found_offers    = 0
    
    if start == 0 && @include_rating_offer && @publisher_app.enabled_rating_offer_id.present?
      rate_app_offer = Offer.find_in_cache(enabled_rating_offer_id)
      if rate_app_offer.present? && rate_app_offer.accepting_clicks? && !rate_app_offer.postcache_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version, @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size, @video_offer_ids)
        returned_offers << rate_app_offer
        found_offers += 1
      end
    end
    
    @offers.each_with_index do |offer, i|
      return [ returned_offers, @offers.length - i ] if found_offers >= offers_to_find
      
      unless offer.postcache_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version, @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size, @video_offer_ids)
        returned_offers << offer if found_offers >= start
        found_offers += 1
      end
    end
    
    [ returned_offers, 0 ]
  end
  
end
