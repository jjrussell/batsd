class Apps::ActionOffersController < WebsiteController
  layout 'apps'
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
  end

  def preview
    @show_generated_ads = @offer.uploaded_icon?
    render 'apps/offers_shared/preview', :layout => false
  end

  def update
    params[:action_offer][:primary_offer_attributes].delete(:payment)
    params[:action_offer][:primary_offer_attributes][:daily_budget].gsub!(',', '') if params[:action_offer][:primary_offer_attributes][:daily_budget].present?
    params[:action_offer][:primary_offer_attributes][:daily_budget] = 0 if params[:daily_budget] == 'off'
    params[:action_offer][:primary_offer_attributes] = sanitize_currency_params(params[:action_offer][:primary_offer_attributes], [ :bid, :min_bid_override ])

    safe_attributes = [ :name, :prerequisite_offer_id, :instructions, :primary_offer_attributes_id, :primary_offer_attributes_bid, :primary_offer_attributes_user_enabled,
      :primary_offer_attributes_daily_budget, :primary_offer_attributes_min_os_version, :primary_offer_attributes_screen_layout_sizes, :primary_offer_attributes_self_promote_only ]

    if permitted_to? :edit, :statz
      safe_attributes += [
        :primary_offer_attributes_tapjoy_enabled,
        :primary_offer_attributes_allow_negative_balance,
        :primary_offer_attributes_pay_per_click,
        :primary_offer_attributes_name_suffix,
        :primary_offer_attributes_show_rate,
        :primary_offer_attributes_min_conversion_rate,
        :primary_offer_attributes_countries,
        :primary_offer_attributes_dma_codes,
        :primary_offer_attributes_regions,
        :primary_offer_attributes_device_types,
        :primary_offer_attributes_publisher_app_whitelist,
        :primary_offer_attributes_overall_budget,
        :primary_offer_attributes_min_bid_override,
      ]
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
        render :text => @app.generate_actions_file, :format => Mime::TEXT
      end
    end
  end

  def TapjoyPPA
    respond_to do |format|
      format.java do
        render :text => @app.generate_actions_file, :format => Mime::TEXT
      end
    end
  end

private

  def setup
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id])
    else
      @app = current_partner.apps.find(params[:app_id])
    end

    if params[:id]
      @action_offer = @app.action_offers.find(params[:id])
      @offer = @action_offer.primary_offer
      log_activity(@action_offer)
      log_activity(@offer)
    end
  end

end
