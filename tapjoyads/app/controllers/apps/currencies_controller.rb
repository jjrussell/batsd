class Apps::CurrenciesController < WebsiteController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :find_currency, :only => [ :show, :update, :reset_test_device ]
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def show
    @udids_to_check = @currency.get_test_device_ids.map do |id|
      device = Device.new(:key => id)
      if device.has_app(@app.id)
        last_run_time = device.last_run_time(@app.id).to_s(:pub_ampm_sec)
      else
        last_run_time = "Never"
      end
      [id, last_run_time]
    end
    unless @currency.tapjoy_enabled?
      flash.now[:warning] = 'Please note that you must get approval before users will be able to earn currency.'
    end
  end

  def update
    log_activity(@currency)

    currency_params = sanitize_currency_params(params[:currency], [ :minimum_featured_bid ])
    
    if params[:managed_by_tapjoy]
      params[:currency][:callback_url] = Currency::TAPJOY_MANAGED_CALLBACK_URL
    end
    
    safe_attributes = [:name, :conversion_rate, :initial_balance, :callback_url, :secret_key, :test_devices, :minimum_featured_bid]
    if permitted_to?(:edit, :statz)
      safe_attributes += [:disabled_offers, :max_age_rating, :only_free_offers, :ordinal, :banner_advertiser]
    end
    
    if @currency.safe_update_attributes(currency_params, safe_attributes)
      flash[:notice] = 'Currency was successfully updated.'
      redirect_to app_currency_path(:app_id => @app.id, :id => @currency.id)
    else
      flash.now[:error] = 'Update unsuccessful'
      render :action => :show
    end
  end
  
  def new
    @app = current_partner.apps.find(params[:app_id])
    @currency = Currency.new
  end
  
  def create
    @app = current_partner.apps.find(params[:app_id], :include => :currencies)
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
      @currency.ordinal = @app.currencies.last.ordinal + 100
    end
    
    log_activity(@currency)
    @currency.name = params[:currency][:name]
    
    if @currency.save
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

  def find_currency
    @app = current_partner.apps.find_by_id(params[:app_id], :include => [:primary_currency])
    if @app.nil?
      redirect_to apps_path
      return
    end
    @currency = @app.currencies.find_by_id(params[:id])
    if @currency.nil?
      flash[:error] = "Could not find currency"
      redirect_to apps_path
    end
  end

end
