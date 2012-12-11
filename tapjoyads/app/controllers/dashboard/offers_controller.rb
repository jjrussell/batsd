class Dashboard::OffersController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all
  before_filter :setup, :except => [ :toggle ]
  after_filter :save_activity_logs, :only => [ :create, :update, :toggle ]

  BASE_SAFE_ATTRIBUTES     = [ :daily_budget, :user_enabled, :bid, :self_promote_only,
                               :min_os_version, :screen_layout_sizes, :countries,
                               :prerequisite_offer_id, :exclusion_prerequisite_offer_ids, :daily_cap_type,
                               :featured_ad_action, :featured_ad_content, :featured_ad_color ]

  ELEVATED_SAFE_ATTRIBUTES = BASE_SAFE_ATTRIBUTES | [ :tapjoy_enabled, :allow_negative_balance, :pay_per_click,
                               :name, :name_suffix, :audition_factor, :show_rate, :min_conversion_rate,
                               :device_types, :publisher_app_whitelist, :overall_budget, :min_bid_override,
                               :dma_codes, :regions, :carriers, :cities, :rate_filter_override,
                               :x_partner_prerequisites, :x_partner_exclusion_prerequisites, :requires_mac_address,
                               :requires_udid, :requires_advertising_id ]

  def new
    offer_params = {}
    if params[:offer_type] == 'rewarded_featured'
      offer_params = {:featured => true, :rewarded => true}
    elsif params[:offer_type] == 'non_rewarded_featured'
      offer_params = {:featured => true, :rewarded => false}
    elsif params[:offer_type] == 'non_rewarded'
      offer_params = {:featured => false, :rewarded => false}
    else
      offer_params = {:featured => false, :rewarded => true}
    end
    @offer = Offer.new(offer_params)
  end

  def create
    object = @distribution ? @distribution : @app
    if params[:offer_type] == 'rewarded_featured'
      @offer = object.primary_rewarded_featured_offer || object.primary_offer.create_rewarded_featured_clone
    elsif params[:offer_type] == 'non_rewarded_featured'
      @offer = object.primary_non_rewarded_featured_offer || object.primary_offer.create_non_rewarded_featured_clone
    elsif params[:offer_type] == 'non_rewarded'
      @offer = object.primary_non_rewarded_offer || object.primary_offer.create_non_rewarded_clone
    end
    redirect_to :action => :edit, :id => @offer.id
  end

  def edit
    if !@offer.tapjoy_enabled?
      if @offer.rewarded? && !@offer.featured?
        if @offer.integrated?
          flash.now[:notice] = "When you are ready to go live with this campaign, please click the button below to submit an enable app request."
        else
          flash.now[:warning] = "Please note that you must integrate the <a href='#{@offer.item.sdk_url(:connect)}'>Tapjoy advertiser library</a> before we can enable your campaign"
        end
      end

      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
    end
  end

  def update
    params[:offer].delete(:payment)

    params[:offer][:daily_budget].gsub!(',', '') if params[:offer][:daily_budget].present?
    if params[:daily_budget_toggle] == 'off'
      params[:offer][:daily_budget] = 0
      params[:offer][:daily_cap_type] = nil
    end
    offer_params = sanitize_currency_params(params[:offer], [ :bid, :min_bid_override ])

    safe_attributes = BASE_SAFE_ATTRIBUTES
    if permitted_to? :edit, :dashboard_statz
      safe_attributes = ELEVATED_SAFE_ATTRIBUTES
    end

    if @offer.safe_update_attributes(offer_params, safe_attributes)
      flash[:notice] = 'Your offer was successfully updated.'
      redirect_to :action => :edit
    else
      if @offer.enable_offer_requests.pending.present?
        @enable_request = @offer.enable_offer_requests.pending.first
      else
        @enable_request = @offer.enable_offer_requests.build
      end
      flash.now[:error] = 'Your offer could not be updated.'
      render :action => :edit
    end
  end

  def toggle
    @offer = current_partner.offers.find(params[:id])
    log_activity(@offer)

    @offer.user_enabled = params[:user_enabled]
    status = @offer.save ? 200 : 500
    render :json => '', :status => status
  end

  def percentile
    @offer.bid = sanitize_currency_param(params[:bid])
    estimate = @offer.percentile
    render :json => { :percentile => estimate, :ordinalized_percentile => estimate.ordinalize }
  rescue
    render :json => { :percentile => "N/A", :ordinalized_percentile => "N/A" }
  end

  private

  def setup
    @app = find_app(params[:app_id], :redirect_on_nil => false)
    if @app.nil?
      redirect_on_app_not_found(params[:app_id]) and return
    end

    if params[:id]
      @offer = @app.offers.find(params[:id])
      @app_metadata = @offer.app_metadata
      @distribution = @app.app_metadata_mappings.find_by_app_metadata_id(@app_metadata.id) if @app_metadata
    elsif params[:app_metadata_id]
      @distribution = @app.app_metadata_mappings.find_by_app_metadata_id(params[:app_metadata_id])
      @app_metadata = @distribution.app_metadata
      @offer = @distribution.primary_offer
    else
      @offer = @app.primary_offer
      @app_metadata = @app.primary_app_metadata
      @distribution = @app.app_metadata_mappings.find_by_is_primary(true)
    end
    log_activity(@offer)
  end
end
