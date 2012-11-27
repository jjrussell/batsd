class Dashboard::Tools::OfferListsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  OFFER_LIST_KEYS = %w( type device_type platform_name udid tapjoy_device_id source currency_id store_name )

  def index
    return unless verify_params(:type, :currency_id)
    geoip_params = params.slice(:primary_country, :city, :dma_code, :region)
    offer_list_params = params.reject { |k,v| !OFFER_LIST_KEYS.include?(k) }.merge(:geoip_data => geoip_params)
    offer_list = OfferList.new(offer_list_params)
    @offers = offer_list.sorted_offers_with_rejections(params[:currency_group_id])
  end
end
