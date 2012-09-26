class Dashboard::Tools::OptimizedOfferListsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  OFFER_LIST_KEYS = %w( type device_type platform_name udid source currency_id algorithm )

  def index
    @key = s3_key(params)
    @cache_key = cache_key(@key)
    @raw_offers = raw_offers(@key) if params[:raw_offers]
    @keys = all_available_keys if params[:all_keys]
    if params[:processed_offers]
      @offers = processed_offers(params)
      if params[:hide_rejected]
        @offers = @offers.select{ |offer| offer.rejections.empty? }
      end
    end
  end

  private

  # TODO: Don't use private methods here

  def processed_offers(params)
    params[:platform_name] = params[:platform]
    params[:primary_country] = params[:country]
    geoip_params = params.slice(:primary_country, :city, :dma_code, :region)
    offer_list_params = params.reject { |k,v| !OFFER_LIST_KEYS.include?(k) }.merge(:geoip_data => geoip_params)
    offer_list = OfferList.new(offer_list_params)
    offer_list.sorted_optimized_offers_with_rejections #(params[:currency_group_id])
  end

  def s3_key(params)
    options = Hash[OptimizedOfferList::ORDERED_KEY_ELEMENTS.map{ |e| [e, params[e]] }]
    OptimizedOfferList.send(:s3_key_for_options, options)
  end

  def cache_key(key)
    opts = OptimizedOfferList.send(:options_for_s3_key, key)
    OptimizedOfferList.send(:cache_key_for_options, opts)
  end

  def raw_offers(key)
    OptimizedOfferList.send(:s3_json_offer_data, key).first['offers'] rescue []
  end

  def all_available_keys
    OptimizedOfferList.send(:s3_optimization_keys).map{ |key| { :key => key, :cache_key => cache_key(key) } }
  end

end
