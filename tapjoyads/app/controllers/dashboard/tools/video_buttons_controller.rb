class Dashboard::Tools::VideoButtonsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :find_button, :only => [ :edit, :show, :update ]
  before_filter :find_video_offer
  before_filter :handle_params, :only => [ :create, :update ]
  after_filter :save_activity_logs

  def index
    @video_buttons = @video_offer.video_buttons.ordered
  end

  def new
    @video_button = @video_offer.video_buttons.build
  end

  def edit
  end

  def show
  end

  def create
    @video_button = VideoButton.new(params[:video_button])
    @video_button.item = params[:video_button][:item]
    log_activity(@video_button)

    if @video_button.save
      unless @video_offer.valid_for_update_buttons?
        flash.now[:warning] = 'Support at most 2 enabled buttons.'
        render :action => :new
      else
        flash[:notice] = 'Successfully created Video Button'
        redirect_to :action => :index
      end
    else
      render :action => :new
    end
  end

  def update
    log_activity(@video_button)

    @video_button.item = params[:video_button][:item]
    if @video_button.update_attributes(params[:video_button])
      unless @video_offer.valid_for_update_buttons?
        flash.now[:warning] = 'Support at most 2 enabled buttons.'
        render :action => :edit
      else
        flash[:notice] = 'Successfully updated Video Button'
        redirect_to :action => :show
      end
    else
      render :action => :edit
    end
  end

private
  def handle_params
    if item_id = params[:video_button][:item_id]
      type, id = item_id.split(':')
      params[:video_button][:item] = type.constantize.find(id)
    end
  end

  def find_button
    @video_button = VideoButton.find(params[:id], :include => :video_offer)
  end

  def find_video_offer
    @video_offer = VideoOffer.find(params[:video_offer_id])
  end
end
