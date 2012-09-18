class Dashboard::CurrenciesController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :setup
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def show
    redirect_to app_non_rewarded_index_path(:app_id => @app.id) unless @currency.rewarded?
    @udids_to_check = @currency.get_test_device_ids.map do |id|
      device = Device.new(:key => id)
      if device.has_app?(@app.id)
        last_run_time = device.last_run_time(@app.id).to_s(:pub_ampm_sec)
      else
        last_run_time = "Never"
      end
      [id, last_run_time]
    end
    unless @currency.tapjoy_enabled?
      flash.now[:warning] = "This virtual currency is currently disabled. Please email <a href='mailto:support+enable@tapjoy.com?subject=reenable+currency+ID+#{@currency.id}'>support+enable@tapjoy.com</a> with your app ID to have it enabled. If your application is currently not live, please provide a brief explanation of how you intend to use virtual currency your app."
    end
  end

  def update
    log_activity(@currency)
    currency_params = sanitize_currency_params(params[:currency], [ :minimum_featured_bid, :minimum_offerwall_bid, :minimum_display_bid ])

    if params[:managed_by_tapjoy]
      params[:currency][:callback_url] = Currency::TAPJOY_MANAGED_CALLBACK_URL
    end

    safe_attributes = [:name, :conversion_rate, :initial_balance, :callback_url, :secret_key, :test_devices, :minimum_featured_bid, :minimum_offerwall_bid, :minimum_display_bid]
    if permitted_to?(:edit, :dashboard_statz)
      safe_attributes += [:disabled_offers, :max_age_rating, :only_free_offers, :ordinal, :hide_rewarded_app_installs, :minimum_hide_rewarded_app_installs_version, :tapjoy_enabled, :rev_share_override, :send_offer_data]
    end

    if @currency.safe_update_attributes(currency_params, safe_attributes)
      flash[:notice] = 'Successfully updated.'
      redirect_to app_currency_path(:app_id => @app.id, :id => @currency.id) if @currency.rewarded?
    else
      flash.now[:error] = 'Update unsuccessful'
      render :show and return if @currency.rewarded?
    end
    redirect_to app_non_rewarded_index_path(:app_id => @app.id) unless @currency.rewarded?
  end

  def new
    @currency = Currency.new
  end

  def create
    unless @app.can_have_new_currency?
      flash[:error] = 'Cannot create currency for this app.'
      redirect_to apps_path and return
    end

    if @app.currencies.empty?
      @currency = Currency.new
      @currency.id = @app.id
      @currency.app = @app
      @currency.partner = @app.partner
      @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.ordinal = 1
    else
      @currency = @app.currencies.first.clone
      @currency.attributes = { :created_at => nil, :updated_at => nil, :ordinal => (@app.currencies.last.ordinal + 100) }
    end

    log_activity(@currency)
    @currency.name = params[:currency][:name]

    partner = @currency.partner

    unless partner.accepted_publisher_tos? || params[:terms_of_service] == '1'
      flash[:error] = 'You must accept the terms of service to create a new virtual currency'
      render :action => :new and return
    end

    if @currency.save
      if params[:terms_of_service] == '1'
        log_activity(partner)
        partner.update_attribute :accepted_publisher_tos, true
      end
      flash[:notice] = 'Currency was successfully created.'
      redirect_to app_currency_path(:app_id => params[:app_id], :id => @currency.id)
    else
      flash.now[:error] = 'Failed to create currency.'
      render :action => :new
    end
  end

  def reset_test_device
    if @currency.get_test_device_ids.include?(params[:udid])
      PointPurchases.transaction(:key => "#{params[:udid]}.#{params[:app_id]}") do |point_purchases|
        point_purchases.virtual_goods = {}
        point_purchases.points = @currency.initial_balance if params[:reset_balance] == '1'
      end
      flash[:notice] = "You have successfully removed all virtual goods for #{params[:udid]}."
    else
      flash[:error] = "#{params[:udid]} is not a test device."
    end
    redirect_to app_currency_path(:app_id => @app.id, :id => @currency.id)
  end

  private
  def setup
    @app = find_app(params[:app_id])

    if params[:id]
      if @app.non_rewarded.try(:id) == params[:id]
        @currency = @app.non_rewarded
      else
        @currency = @app.currencies.find(params[:id])
      end
    end
  end

end
