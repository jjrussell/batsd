class Dashboard::Tools::OfferListsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  OFFER_LIST_KEYS = %w( type device_type platform_name udid source currency_id )

  def index
    if params[:type]
      geoip_params = params.slice(:primary_country, :city, :dma_code, :region)
      offer_list_params = params.reject { |k,v| !OFFER_LIST_KEYS.include?(k) }.merge(:geoip_data => geoip_params)
      offer_list = OfferList.new(offer_list_params)
      @offers = offer_list.sorted_offers_with_rejections(params[:currency_group_id])
    end
  end
end
