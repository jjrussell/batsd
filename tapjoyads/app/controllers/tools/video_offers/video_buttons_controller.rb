class Tools::VideoOffers::VideoButtonsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  
  before_filter :find_button, :only => [ :edit, :show, :update, :destroy ]
  before_filter :find_video_offer
  after_filter :save_activity_logs
  
  def index
    @video_buttons = VideoOffer.find(params[:video_offer_id]).video_buttons.sort_by {|button| button.ordinal}
  end
  
  def new
    @video_button = VideoButton.new(:video_offer_id => params[:video_offer_id])
  end
  
  def edit
  end
  
  def show
  end
  
  def create
    return unless verify_params([ :video_offer_id ], { :render_missing_text => false })

    @video_button = VideoButton.new(params[:video_button])
    log_activity(@video_button)
    
    if @video_button.save
      flash[:notice] = 'Successfully created Video Button'
      redirect_to :action => :index
    else
      render :action => :new
    end
  end
  
  def update
    log_activity(@video_button)
    
    if @video_button.update_attributes(params[:video_button])
      flash[:notice] = 'Successfully updated Video Button'
      redirect_to :action => :show
    else
      render :action => :edit
    end
  end
  
  def destroy
    @video_button.destroy
    flash[:notice] = 'Successfully destroyed Video Button'
    redirect_to :action => :index
  end

private

  def find_button
    return unless verify_params([ :id ], { :render_missing_text => false })
    
    @video_button = VideoButton.find(params[:id], :include => :video_offer)
  end
  
  def find_video_offer
    @video_offer = VideoOffer.find(params[:video_offer_id])
  end
end