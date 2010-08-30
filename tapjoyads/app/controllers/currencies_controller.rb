class CurrenciesController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all

  before_filter :find_currency, :only => [ :show, :update ]

  def show
  end
  
  def update
    if params[:managed_by_tapjoy]
      params[:currency][:callback_url] = Currency::TAPJOY_MANAGED_CALLBACK_URL
    end
    
    if @currency.safe_update_attributes(params[:currency], [:name, :conversion_rate, :initial_balance, :callback_url, :secret_key, :test_devices])
      flash[:notice] = 'Currency was successfully updated.'
      redirect_to app_currency_path(:app_id => params[:app_id], :id => @currency.id)
    else
      flash[:error] = 'Update unsuccessful'
      render :action => :show
    end
  end
  
  def new
    @app = App.find(params[:app_id])
    @currency = Currency.new
    @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
    render :action => :show
  end
  
  def create
    @app = App.find(params[:app_id])
    @currency = Currency.new
    @currency.app = @app
    @currency.partner = @app.partner
    update
  end
  
private
  
  def find_currency
    @currency = Currency.find_by_id(params[:id])
    if @currency.nil?
      flash[:error] = "Could not find currency"
      redirect_to apps_path
    else
      @app = @currency.app
    end
  end
  
end