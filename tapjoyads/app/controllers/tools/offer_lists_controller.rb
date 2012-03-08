class Tools::OfferListsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    if params[:type]
      offer_list_params = params.reject { |k,v| !OfferList::OFFER_LIST_KEYS.include?(k) }
      udid = offer_list_params.delete(:udid)
      offer_list_params[:device] = Device.new(:key => udid) if params[:udid].present?
      offer_list = OfferList.new(offer_list_params)
      @offers = offer_list.offers.sort_by { |offer| -offer.precache_rank_score_for(params[:currency_group_id]) }
      @offer_rejections =  offer_list.rejected_reasons(@offers)
    end
  end

end
