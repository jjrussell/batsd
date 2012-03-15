class Tools::OfferListsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  OFFER_LIST_KEYS = %w( type device_type platform_name udid source )

  def index
    if params[:type]
      offer_list_params = params.reject { |k,v| !OFFER_LIST_KEYS.include?(k) }
      offer_list = OfferList.new(offer_list_params)
      @offers = offer_list.rank_sorted_offers_with_rejections(params[:currency_group_id])
    end
  end
end
