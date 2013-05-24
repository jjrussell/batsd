class Dashboard::ActionOffersController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps
  before_filter :setup
  filter_access_to :all
  after_filter :save_activity_logs, :only => [ :create, :update, :toggle ]

  BASE_SAFE_ATTRIBUTES = %w(name prerequisite_offer_id exclusion_prerequisite_offer_ids instructions primary_offer_attributes_id primary_offer_attributes_featured x_partner_prerequisites x_partner_exclusion_prerequisites)

  BASE_OFFER_SAFE_ATTRIBUTES = Dashboard::OffersController::BASE_SAFE_ATTRIBUTES.map do |attribute|
    "primary_offer_attributes_#{attribute}"
  end

  ELEVATED_OFFER_SAFE_ATTRIBUTES = Dashboard::OffersController::ELEVATED_SAFE_ATTRIBUTES.map do |attribute|
    "primary_offer_attributes_#{attribute}"
  end

  def index
    @action_offers = @app.action_offers
  end

  def new
    @action_offer = @app.action_offers.build :partner => current_partner
  end

  def create
    action_offer_params = params[:action_offer].merge(:partner => current_partner, :prerequisite_offer => @app.primary_offer, :instructions => 'Enter your instructions here.')
    @action_offer = @app.action_offers.build action_offer_params
    if @action_offer.save
      redirect_to edit_app_action_offer_path(@app, @action_offer)
    else
      render :new
    end
  end

  def edit
    if !@action_offer.tapjoy_enabled? && !@action_offer.integrated?
      flash.now[:notice] = "When you are ready to go live with this action, please click the button below to submit an enable offer request."
    end

    if @offer.enable_offer_requests.pending.present?
      @enable_request = @offer.enable_offer_requests.pending.first
    else
      @enable_request = @offer.enable_offer_requests.build
    end

    if @action_offer.platform == 'iphone' && @offer.prerequisite_offer_id.blank?
      flash.now[:warning] = "This offer will not be shown on in-app Offerwall of an iOS device unless there's a prerequisite. It will still be shown on Tapjoy.com"
    end
  end

  def preview
    @show_generated_ads = @offer.uploaded_icon?
    render 'dashboard/offer_creatives/show', :layout => false
  end

  def update
    params[:action_offer][:primary_offer_attributes].delete(:payment)
    params[:action_offer][:primary_offer_attributes][:daily_budget].gsub!(',', '') if params[:action_offer][:primary_offer_attributes][:daily_budget].present?
    params[:action_offer][:primary_offer_attributes][:daily_budget] = 0 if params[:daily_budget] == 'off'
    params[:action_offer][:primary_offer_attributes] = sanitize_currency_params(params[:action_offer][:primary_offer_attributes], [ :bid, :min_bid_override ])

    if permitted_to? :edit, :dashboard_statz
      safe_attributes = BASE_SAFE_ATTRIBUTES + ELEVATED_OFFER_SAFE_ATTRIBUTES
    else
      safe_attributes = BASE_SAFE_ATTRIBUTES + BASE_OFFER_SAFE_ATTRIBUTES
    end

    if @action_offer.safe_update_attributes params[:action_offer], safe_attributes
      flash[:notice] = "Updated the '#{@action_offer.name}' action."
      redirect_to app_action_offers_path(@app)
    else
      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
      flash.now[:error] = "Could not save '#{@action_offer.name}' action."
      render :edit
    end
  end

  def toggle
    if @action_offer.toggle_user_enabled
      render :json => { :success => true, :user_enabled => @action_offer.user_enabled? }
    else
      render :json => { :success => false }
    end
  end

  def TJCPPA
    respond_to do |format|
      format.h do
        send_data(@app.generate_actions_file, :filename => "TJCPPA.h", :type => "text/plain")
      end
    end
  end

  def TapjoyPPA
    respond_to do |format|
      format.java do
        send_data(@app.generate_actions_file, :filename => "TapjoyPPA.java", :type => "text/plain")
      end
    end
  end

  private

  def setup
    @app = find_app(params[:app_id])

    if params[:id]
      @action_offer = @app.action_offers.find(params[:id])
      @offer = @action_offer.primary_offer
      log_activity(@action_offer)
      log_activity(@offer)
    end
  end

end
