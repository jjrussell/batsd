class Apps::ActionOffersController < WebsiteController
  layout 'tabbed'
  current_tab :apps
  before_filter :setup
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update, :toggle ]
  
  def index
    @action_offers = @app.action_offers
  end
  
  def new
    @action_offer = @app.action_offers.build :partner => current_partner
  end
  
  def create
    action_offer_params = params[:action_offer].merge(:partner => current_partner)
    @action_offer = @app.action_offers.build action_offer_params
    if @action_offer.save
      redirect_to edit_app_action_offer_path(@app, @action_offer)
    else
      render :new
    end
  end
  
  def edit
    
  end
  
  def update
    params[:action_offer][:primary_offer_attributes].delete(:payment)
    params[:action_offer][:primary_offer_attributes] = sanitize_currency_params(params[:action_offer][:primary_offer_attributes], [ :bid, :min_bid_override ])
    
    safe_attributes = [ :name, :instructions, :primary_offer_attributes_id, :primary_offer_attributes_bid, :primary_offer_attributes_user_enabled, :primary_offer_attributes_daily_budget ]
    
    if permitted_to? :edit, :statz
      safe_attributes += [
        :primary_offer_attributes_tapjoy_enabled,
        :primary_offer_attributes_self_promote_only,
        :primary_offer_attributes_allow_negative_balance,
        :primary_offer_attributes_pay_per_click,
        :primary_offer_attributes_min_conversion_rate,
        :primary_offer_attributes_publisher_app_whitelist,
        :primary_offer_attributes_overall_budget,
        :primary_offer_attributes_min_bid_override
      ]
    end
    
    if @action_offer.safe_update_attributes params[:action_offer], safe_attributes
      flash[:notice] = "Updated the '#{@action_offer.name}' action."
      redirect_to app_action_offers_path(@app)
    else
      flash[:error] = "Could not save '#{@action_offer.name}' action."
      render :edit
    end
  end
  
  def toggle
    @action_offer.primary_offer.user_enabled = !@action_offer.primary_offer.user_enabled
    if @action_offer.primary_offer.save
      render :json => { :success => true, :user_enabled => @action_offer.primary_offer.user_enabled }
    else
      render :json => { :success => false }
    end
  end

private

  def setup
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id], :include => [:action_offers])
    else
      @app = current_partner.apps.find(params[:app_id], :include => [:action_offers])
    end
    
    if params[:id]
      @action_offer = @app.action_offers.find(params[:id])
      log_activity(@action_offer)
    end
  end

end
