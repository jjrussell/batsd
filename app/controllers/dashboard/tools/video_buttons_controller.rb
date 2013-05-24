class Dashboard::Tools::VideoButtonsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_button, :only => [ :edit, :update ]
  before_filter :find_video_offer
  after_filter :save_activity_logs

  def index
    @video_buttons = @video_offer.video_buttons.ordered
  end

  def new
    @video_button = @video_offer.video_buttons.build
  end

  def edit
  end

  def create
    @video_button = VideoButton.new(params[:video_button])
    log_activity(@video_button)

    if @video_button.save
      flash[:notice] = 'Successfully created Video Button'
      redirect_to :action => :index
    else
      flash[:error] = 'Unable to create Video Button'
      render :action => :new
    end
  end

  def update
    log_activity(@video_button)

    if @video_button.update_attributes(params[:video_button])
      flash[:notice] = 'Successfully updated Video Button'
      redirect_to :action => :index
    else
      render :action => :edit
    end
  end

private

  def find_button
    @video_button = VideoButton.find(params[:id], :include => :video_offer)
  end

  def find_video_offer
    @video_offer = VideoOffer.find(params[:video_offer_id])
  end
end
