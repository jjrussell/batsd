class Apps::ReengagementOffersController < WebsiteController
  layout 'apps'
  current_tab :apps
  before_filter :setup
  filter_access_to :all



  def index
    @reengagement_offers = @app.reengagement_offers
  end

  def new
    @reengagement_offer = @app.reengagement_offers.build :partner => current_partner
  end

  def create
    reengagement_offer_params = params[:reengagement_offer].merge(:partner => current_partner, :prerequisite_offer => @app.primary_offer, :instructions => 'Enter your instructions here.')
    @reengagement_offer = @app.reengagement_offers.build reengagement_offer_params
    if @reengagement_offer.save
      redirect_to edit_app_reengagement_offer_path(@app, @reengagement_offer)
    else
      render :new
    end
  end

  def edit
    # handle disabled/non-integrated here

    if @offer.enable_offer_requests.pending.present?
      @enable_request = @offer.enable_offer_requests.pending.first
    else
      @enable_request = @offer.enable_offer_requests.build
    end
  end

  def update
    params[:reengagement_offer][:primary_offer_attributes].delete(:payment)
    params[:reengagement_offer][:primary_offer_attributes][:daily_budget].gsub!(',', '') if params[:reengagement_offer][:primary_offer_attributes][:daily_budget].present?
    params[:reengagement_offer][:primary_offer_attributes][:daily_budget] = 0 if params[:daily_budget] == 'off'
    params[:reengagement_offer][:primary_offer_attributes] = sanitize_currency_params(params[:reengagement_offer][:primary_offer_attributes], [ :bid, :min_bid_override ])

    safe_attributes = [ :name, :prerequisite_offer_id, :instructions, :primary_offer_attributes_id, :primary_offer_attributes_bid, :primary_offer_attributes_user_enabled,
      :primary_offer_attributes_daily_budget, :primary_offer_attributes_min_os_version, :primary_offer_attributes_screen_layout_sizes ]

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

    if @reengagement_offer.safe_update_attributes params[:reengagement_offer], safe_attributes
      flash[:notice] = "Updated the '#{@reengagement_offer.name}' reengagement."
      redirect_to app_reengagement_offers_path(@app)
    else
      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
      flash.now[:error] = "Could not save '#{@reengagement_offer.name}' reengagement."
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

  private

  def setup
    if permitted_to? :edit, :statz
      @app = App.find(params[:app_id])
    else
      @app = current_partner.apps.find(params[:app_id])
    end

    if params[:id]
      @reengagement_offer = @app.reengagement_offers.find(params[:id])
      @offer = @reengagement_offer.primary_offer
      log_activity(@reengagement_offer)
      log_activity(@offer)
    end
  end


end
