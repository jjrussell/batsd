class Dashboard::Tools::GenericOffersController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def index
    @generic_offers = GenericOffer.all
  end

  def new
    @generic_offer = GenericOffer.new(:partner_id => params[:partner_id])
    @generic_offer.build_primary_offer
  end

  def edit
    @generic_offer = GenericOffer.find(params[:id], :include => :partner)
  end

  def create
    generic_offer_params = sanitize_currency_params(params[:generic_offer], [ :price ])
    # due to the creation order of the primary_offer at the model level, we need to pull out nested
    # primary_offer_attributes upon creation
    generic_offer_params[:primary_offer_creation_attributes] = generic_offer_params.delete(:primary_offer_attributes)

    @generic_offer = GenericOffer.new(generic_offer_params)

    log_activity(@generic_offer)
    if @generic_offer.save
      @generic_offer.save_icon!(params[:icon].read) unless params[:icon].blank?
      flash[:notice] = 'Successfully created Generic Offer'
      redirect_to statz_path(@generic_offer.primary_offer)
    else
      @generic_offer.build_primary_offer
      render :action => :new
    end
  end

  def update
    @generic_offer = GenericOffer.find(params[:id], :include => :partner)
    generic_offer_params = sanitize_currency_params(params[:generic_offer], [ :price ])
    log_activity(@generic_offer)
    if @generic_offer.update_attributes(generic_offer_params)
      @generic_offer.save_icon!(params[:icon].read) unless params[:icon].blank?
      flash[:notice] = 'Successfully updated Generic Offer'
      redirect_to statz_path(@generic_offer.primary_offer)
    else
      render :action => :edit
    end
  end
end
