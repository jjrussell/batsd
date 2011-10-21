class Tools::VideoOffersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update ]
  
  def new
    @video_offer = VideoOffer.new(:partner_id => params[:partner_id])
  end
  
  def edit
    @video_offer = VideoOffer.find(params[:id], :include => :partner)
  end
  
  def create
    @video_offer = VideoOffer.new(params[:video_offer])
    log_activity(@video_offer)
    
    if params[:video].blank?
      flash.now[:error] = 'Please upload a video'
      render :action => :new and return
    end
    
    if @video_offer.save
      @video_offer.primary_offer.save_video!(params[:video].read)
      @video_offer.primary_offer.save_icon!(params[:icon].read) if params[:icon].present?
      flash[:notice] = 'Successfully created Video Offer'
      redirect_to edit_tools_video_offer_path(@video_offer.id)
    else
      render :action => :new
    end
  end
  
  def update
    @video_offer = VideoOffer.find(params[:id], :include => :partner)
    log_activity(@video_offer)
    
    if @video_offer.update_attributes(params[:video_offer])
      @video_offer.primary_offer.save_video!(params[:video].read) if params[:video].present?
      @video_offer.primary_offer.save_icon!(params[:icon].read) if params[:icon].present?
      flash[:notice] = 'Successfully updated Video Offer'
      redirect_to statz_path(@video_offer.primary_offer)
    else
      render :action => :edit
    end
  end
end
