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
    
    if @video_offer.save
      if params[:video].present?
        @video_offer.primary_offer.save_video!(params[:video].read)
      end
      if params[:icon].present?
        @video_offer.primary_offer.save_icon!(params[:icon].read)
      end
      flash[:notice] = 'Successfully created Video Offer'
      redirect_to statz_path(@video_offer.primary_offer)
    else
      render :action => :new
    end
  end
  
  def update
    @video_offer = VideoOffer.find(params[:id], :include => :partner)
    log_activity(@video_offer)
    
    if @video_offer.update_attributes(params[:video_offer])
      if params[:video].present?
        @video_offer.primary_offer.save_video!(params[:video].read)
      end
      if params[:icon].present?
        @video_offer.primary_offer.save_icon!(params[:icon].read)
      end
      flash[:notice] = 'Successfully updated Video Offer'
      redirect_to statz_path(@video_offer.primary_offer)
    else
      render :action => :edit
    end
  end
end