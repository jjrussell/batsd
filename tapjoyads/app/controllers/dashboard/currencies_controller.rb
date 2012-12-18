class Dashboard::CurrenciesController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :setup
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def show
    warn = params.delete(:warn) { false }
    flash.now[:warning] = "You have made a change that could negatively impact users currently completing offers." if(warn == 'true' && @currency.tapjoy_enabled?)

    @udids_to_check = @currency.get_test_device_ids.map do |id|
      device = Device.new(:key => id)
      if device.has_app?(@app.id)
        last_run_time = device.last_run_time(@app.id).to_s(:pub_ampm_sec)
      else
        last_run_time = "Never"
      end
      [id, last_run_time]
    end
    if @currency.tapjoy_enabled?
      flash.now[:warning] ||= "Changing a currency's callback URL or conversion rate can negatively impact users who are currently completing offers."
    else
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
      if params[:currency][:message_enabled] == "1" && params[:currency][:message].blank?
        @currency.errors.add(:message, "can't be blank")
        render :show and return
      end
      safe_attributes += [:disabled_offers, :max_age_rating, :only_free_offers, :ordinal, :hide_rewarded_app_installs, :tapjoy_enabled, :rev_share_override, :send_offer_data, :message, :message_enabled, :conversion_rate_enabled, :offer_filter_selections, :use_offer_filter_selections]
    end

    old_conversion = @currency.conversion_rate
    old_callback   = @currency.callback_url

    if @currency.safe_update_attributes(currency_params, safe_attributes)
      flash[:notice] = 'Successfully updated.'
      warn = !(@currency.conversion_rate == old_conversion && @currency.callback_url == old_callback)
      redirect_to app_currency_path(:app_id => @app.id, :id => @currency.id, :warn => warn.to_s)
    else
      flash.now[:error] = update_flash_error_message(@app.partner)
      render :action => :show and return
    end
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
      @currency.id = @app.id unless @app.non_rewarded.try(:id) == @app.id
      @currency.app = @app
      @currency.partner = @app.partner
      @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.ordinal = 1
    else
      @currency = @app.currencies.first.clone
      @currency.attributes = { :created_at => nil, :updated_at => nil, :ordinal => (@app.currencies.last.ordinal + 100), :tapjoy_enabled => false }
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
    if @currency.has_test_device?(params[:udid] || params[:mac_address])
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
    @app = App.find(params[:app_id])
    if params[:id]
      @currency = @app.currencies.find(params[:id])
    end
  end

end
