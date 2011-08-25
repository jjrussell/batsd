class Tools::OfferListsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    if params[:type]
      offer_list_keys = [ 'type', 'device_type', 'platform_name', 'hide_rewarded_app_installs' ]
      offer_list_params = params.reject { |k,v| !offer_list_keys.include?(k) }

      @offers = OfferList.new(offer_list_params).offers
    end
  end

end