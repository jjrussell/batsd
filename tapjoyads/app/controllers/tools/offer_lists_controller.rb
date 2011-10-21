class Tools::OfferListsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    if params[:type]
      offer_list_keys = [ 'type', 'device_type', 'platform_name' ]
      offer_list_params = params.reject { |k,v| !offer_list_keys.include?(k) }

      @offers = OfferList.new(offer_list_params).offers.sort_by { |offer| -offer.precache_rank_score_for(params[:currency_group_id]) }
    end
  end

end
