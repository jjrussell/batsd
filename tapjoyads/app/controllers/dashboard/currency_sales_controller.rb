class Dashboard::CurrencySalesController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps
  filter_access_to :all
  before_filter :setup
  before_filter :check_times, :only => [ :update ]
  after_filter :save_activity_logs, :only => [ :update, :create, :destroy ]

  PER_PAGE = 10

  def index
    @page_title = "#{@currency.name} Currency Sales"
  end

  def new
    @page_title = "New Currency Sale"
    @currency_sale = CurrencySale.new
  end

  def create
    @currency_sale = CurrencySale.new(params[:currency_sale]) do |sale|
      sale.currency = @currency
    end
    log_activity(@currency_sale)
    if @currency_sale.save
      flash[:notice] = "Successfully created currency sale"
      redirect_to app_currency_currency_sales_path(:app_id => @app.id, :currency_id => @currency.id)
    else
      flash.now[:error] = error || "Unable to create currency sale"
      render :new
    end
  end

  def edit
    @page_title = "Edit Currency Sale"
    @currency_sale = CurrencySale.find(params[:id])
  end

  def update
    log_activity(@currency_sale)
    if !@currency_sale.past? && @currency_sale.update_attributes(params[:currency_sale])
      flash[:notice] = "Successfully updated the currency sale"
      redirect_to app_currency_currency_sales_path(:app_id => @app.id, :currency_id => @currency.id)
    else
      flash.now[:error] = error || "Unable to update currency sale"
      render :edit
    end
  end

  def destroy
    @currency_sale = CurrencySale.find(params[:id])
    log_activity(@currency_sale)
    if @currency_sale.past?
      flash[:error] = "Unable to delete currency sale that has already been run"
    else
      @currency_sale.disable!
      flash[:notice] = "Successfully removed the currency sale"
    end
    redirect_to app_currency_currency_sales_path(:app_id => @app.id, :currency_id => @currency.id)
  end

  private

  def setup
    @app                     = App.find(params[:app_id])
    @currency                = Currency.find(params[:currency_id])
    currency_sales           = @currency.currency_sales
    @active_currency_sales   = currency_sales.active
    @past_currency_sales     = currency_sales.past.paginate(:page => params[:page], :per_page => PER_PAGE)
    @future_currency_sales   = currency_sales.future.paginate(:page => params[:page], :per_page => PER_PAGE)
    @disabled_currency_sales = currency_sales.disabled.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  # Use any base error as the flash. Base errors are only set for time range problems.
  def error
    @currency_sale.errors[:base].first
  end

  def check_times
    @currency_sale = CurrencySale.find(params[:id])
    params[:currency_sale].delete(:start_time) if @currency_sale.start_time == Time.zone.parse(params[:currency_sale][:start_time])
    params[:currency_sale].delete(:end_time) if @currency_sale.end_time == Time.zone.parse(params[:currency_sale][:end_time])
  end
end
