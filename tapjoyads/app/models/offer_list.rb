class OfferList
  attr_reader :offers
  
  def initialize(options        = {})
    @publisher_app              = options.delete(:publisher_app)           { |k| raise "#{k} is a required argument" }
    @device                     = options.delete(:device)                  { |k| raise "#{k} is a required argument" }
    @currency                   = options.delete(:currency)                { |k| raise "#{k} is a required argument" }
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
    
    @hide_rewarded_app_installs = @currency.hide_rewarded_app_installs_for_version?(@app_version, @source)
    @platform                   = @publisher_app.platform_name
    
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    if @hide_rewarded_app_offers
      @type = case type
      when Offer::FEATURED_OFFER_TYPE
        Offer::NON_REWARDED_FEATURED_OFFER_TYPE
      when Offer::DISPLAY_OFFER_TYPE
        Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      else
        @type
      end
    end
    
    @offers = RailsCache.get_and_put("offers.#{@type}.#{@platform}.#{@hide_rewarded_app_installs}") { OfferCacher.get_unsorted_offers_prerejected(@type, @platform, @hide_rewarded_app_installs) }.value.each { |o| o.calculate_rank_score(@currency) }
  end
  
  def weighted_rand
    offers = @offers.clone
    while offers.any?
      weight_scale = 1 - offers.last.rank_score
      weights = offers.collect { |o| o.rank_score + weight_scale }
      offer = offers.weighted_rand(weights)
      return offer if offer.nil?
      if offer.should_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version, @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size)
        offers.delete(offer)
      else
        return offer
      end
    end
  end
  
  def get_offers(start, max_offers)
    @offers.sort! { |a,b| b.rank_score <=> a.rank_score }
    returned_offers = []
    offers_to_find  = start + max_offers
    found_offers    = 0
    
    if start == 0 && @include_rating_offer && @publisher_app.enabled_rating_offer_id.present?
      rate_app_offer = Offer.find_in_cache(enabled_rating_offer_id)
      if rate_app_offer.present? && rate_app_offer.accepting_clicks? && !rate_app_offer.should_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version, @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size)
        returned_offers << rate_app_offer
        found_offers += 1
      end
    end
    
    @offers.each_with_index do |offer, i|
      return [ returned_offers, @offers.length - i ] if found_offers >= offers_to_find
      
      unless offer.should_reject?(@publisher_app, @device, @currency, @device_type, @geoip_data, @app_version, @direct_pay_providers, @type, @hide_rewarded_app_installs, @library_version, @os_version, @screen_layout_size)
        returned_offers << offer if found_offers >= start
        found_offers += 1
      end
    end
    
    [ returned_offers, 0 ]
  end
  
end
