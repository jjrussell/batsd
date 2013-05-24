class Dashboard::Tools::VideoOffersController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update ]

  def new
    @video_offer = VideoOffer.new(:partner_id => params[:partner_id])
    @video_offer.build_primary_offer
  end

  def edit
    @video_offer = VideoOffer.find(params[:id], :include => :partner)
    @video_offer.age_gating = @video_offer.primary_offer.age_rating
  end

  def create
    # due to the creation order of the primary_offer at the model level, we need to pull out nested
    # primary_offer_attributes upon creation
    params[:video_offer][:primary_offer_creation_attributes] = params[:video_offer].delete(:primary_offer_attributes)

    @video_offer = VideoOffer.new(params[:video_offer])
    log_activity(@video_offer)

    if @video_offer.save
      @video_offer.save_icon!(params[:icon].read) if params[:icon].present?
      flash[:notice] = 'Successfully created Video Offer'
      redirect_to edit_tools_video_offer_path(@video_offer.id)
    else
      @video_offer.build_primary_offer
      render :action => :new
    end
  end

  def update
    @video_offer = VideoOffer.find(params[:id], :include => :partner)
    log_activity(@video_offer)
    if @video_offer.update_attributes(params[:video_offer])
      @video_offer.save_icon!(params[:icon].read) if params[:icon].present?
      flash[:notice] = 'Successfully updated Video Offer'
      redirect_to statz_path(@video_offer.primary_offer)
    else
      render :action => :edit
    end
  end
end
