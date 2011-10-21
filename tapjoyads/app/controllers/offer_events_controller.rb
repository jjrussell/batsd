class OfferEventsController < WebsiteController
  layout 'tabbed'
  filter_access_to :all
  before_filter :check_change_attributes, :only => [ :create, :update ]
  before_filter :setup
  after_filter :save_activity_logs, :only => [ :create, :update, :destroy ]
  
  def index
    if params[:filter] == 'all'
      @event_scope = 'all'
    elsif params[:filter] == 'completed'
      @event_scope = 'completed'
    elsif params[:filter] == 'disabled'
      @event_scope = 'disabled'
    else
      @event_scope = 'upcoming'
    end
    
    @offer_events = offer_events_scope.send(@event_scope)
  end

  def new
    @offer_event = new_offer_event
  end
  
  def create
    @offer_event = new_offer_event
    log_activity(@offer_event)
    @offer_event.attributes = params[:offer_event]
    if @offer_event.save
      flash[:notice] = "Created Event for #{@offer_event.offer.name}."
      redirect_to :action => 'index' and return
    else
      flash.now[:error] = "Event could not be created. #{@offer_event.errors[:base]}"
      render :new and return
    end
  end
  
  def edit
    flash.now[:warning] = 'You are viewing a Scheduled Event that has already been run or disabled.' unless @offer_event.editable?
  end
  
  def update  
    log_activity(@offer_event)
    if @offer_event.update_attributes(params[:offer_event])
      flash[:notice] = "Updated Event for #{@offer_event.offer.name}"
      redirect_to :action => 'index' and return
    else
      flash.now[:error] = "Event could not be updated. #{@offer_event.errors[:base]}"
      render :edit and return
    end
  end

  def destroy
    log_activity(@offer_event)
    @offer_event.disable!
    redirect_to :action => 'index' and return
  end
  
private

  def setup
    @app = App.find(params[:app_id])
    @offer = @app.offers.find(params[:offer_id])
    @offer_event = @offer.events.find(params[:id]) if params[:id]
  end
  
  def new_offer_event
    @offer.events.build
  end
  
  def offer_events
    @offer.events
  end

  def check_change_attributes
    if params[:daily_budget_selector] == 'Unchanged'
      params[:offer_event][:daily_budget] = nil
    elsif params[:daily_budget_selector] == 'Unlimited'
      params[:offer_event][:daily_budget] = 0
    end
    
    params[:offer_event][:change_daily_budget] = params[:daily_budget_selector] != 'Unchanged'
    params[:offer_event][:change_user_enabled] = !(params[:offer_event][:user_enabled] == "")
  end

end
