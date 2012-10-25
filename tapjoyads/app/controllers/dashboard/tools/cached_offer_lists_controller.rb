class Dashboard::Tools::CachedOfferListsController < Dashboard::DashboardController
  layout 'dashboard'
  current_tab :tools

  def index
    @cached_offer_lists = CachedOfferList.select(:where => 'generated_at is not NULL', :order_by => 'generated_at DESC', :limit => 50)[:items]
  end

  def show
    @cached_offer_list = CachedOfferList::S3CachedOfferList.find_by_id(params[:id])
    unless @cached_offer_list.present?
      flash[:error] = "Could not find a Cached Offer List with ID = #{params[:id]}"
      redirect_to :action => :index and return
    end
  end
end
