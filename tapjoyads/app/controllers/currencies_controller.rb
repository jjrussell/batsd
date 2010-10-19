class CurrenciesController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all

  before_filter :find_currency, :only => [ :show, :update, :reset_beta_device ]
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def show
  end
  
  def update
    log_activity(@currency)
    
    if params[:managed_by_tapjoy]
      params[:currency][:callback_url] = Currency::TAPJOY_MANAGED_CALLBACK_URL
    end
    
    safe_attributes = [:name, :conversion_rate, :initial_balance, :callback_url, :secret_key, :test_devices]
    if permitted_to?(:index, :statz)
      safe_attributes += [:disabled_offers, :disabled_partners, :max_age_rating, :only_free_offers, :offers_money_share, :installs_money_share]
    end
    
    if @currency.safe_update_attributes(params[:currency], safe_attributes)
      flash[:notice] = 'Currency was successfully updated.'
      redirect_to app_currency_path(:app_id => params[:app_id], :id => @currency.id)
    else
      flash[:error] = 'Update unsuccessful'
      render :action => :show
    end
  end
  
  def new
    @app = current_partner.apps.find(params[:app_id])
    @currency = Currency.new
    @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
    render :action => :show
  end
  
  def create
    @app = current_partner.apps.find(params[:app_id])
    @currency = Currency.new
    @currency.app = @app
    @currency.partner = @app.partner
    update
  end


  ##
  # Removes all virtual goods from a device, only if the device is a beta device.
  def reset_beta_device
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    publisher_user_id = params[:udid]
    publisher_user_id = params[:publisher_user_id] unless params[:publisher_user_id].blank?
    raise NotABetaDevice.new unless @app.currency.get_test_device_ids.include?(params[:udid])

    PointPurchases.transaction(:key => "#{publisher_user_id}.#{params[:app_id]}") do |point_purchases|
      point_purchases.virtual_goods = {}
    end

    flash[:notice] = "You have successfully removed all virtual goods for #{params[:udid]}."
  rescue NotABetaDevice => e
    flash[:error] = "Error: Not a beta device"
  ensure
    redirect_to :back
  end
private

  def find_currency
    @app = current_partner.apps.find_by_id(params[:app_id], :include => [:currency])
    if @app.nil?
      redirect_to apps_path
      return
    end
    @currency = @app.currency
    if @currency.nil?
      flash[:error] = "Could not find currency"
      redirect_to apps_path
    end
  end

  class NotABetaDevice < RuntimeError;end
end
