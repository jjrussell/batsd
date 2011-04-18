class Tools::GenericOffersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create ]
  
  def new
    @generic_offer = GenericOffer.new
  end

  def create
    generic_offer_params = sanitize_currency_params(params[:generic_offer], [ :price ])
    @generic_offer = GenericOffer.new(generic_offer_params)
    log_activity(@generic_offer)
    if @generic_offer.save
      unless params[:icon].blank?
        @generic_offer.primary_offer.save_icon!(params[:icon].read)
      end
      flash[:notice] = 'Successfully created Generic Offer'
      redirect_to statz_path(@generic_offer.primary_offer)
    else
      render :action => :new
    end
  end
end
