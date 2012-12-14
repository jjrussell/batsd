class Dashboard::ConversionRatesController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :setup
  before_filter :generate_graph, :only => [:index, :new, :edit]
  after_filter :save_activity_logs, :only => [:update, :create, :destroy]

  def index
    @page_title = "Conversion Rate Settings"
  end

  def edit
    @conversion_rate = ConversionRate.find(params[:id])
    @page_title = "Edit a Conversion Rate"
  end

  def update
    @conversion_rate = ConversionRate.find(params[:id])
    log_activity(@conversion_rate)
    conversion_rate_params = sanitize_currency_params(params[:conversion_rate], [:minimum_offerwall_bid])
    if @conversion_rate.update_attributes(conversion_rate_params)
      flash[:notice] = "Successfully updated the conversion rate."
      redirect_to app_currency_conversion_rates_path(:app_id => @app.id, :currency_id => @currency.id)
    else
      generate_graph
      flash.now[:error] = error || "Unable to update this conversion rate."
      render :edit
    end
  end

  def new
    @conversion_rate = ConversionRate.new
    @page_title = "Create a new Conversion Rate"
  end

  def create
    conversion_rate_params = sanitize_currency_params(params[:conversion_rate], [:minimum_offerwall_bid])
    @conversion_rate = @currency.conversion_rates.build(conversion_rate_params)
    log_activity(@conversion_rate)
    if @conversion_rate.save
      flash[:notice] = "Successfully created a conversion rate."
      redirect_to app_currency_conversion_rates_path(:app_id => @app.id, :currency_id => @currency.id)
    else
      generate_graph
      flash.now[:error] = error || "Unable to create this conversion rate."
      render :new
    end
  end

  def destroy
    @conversion_rate = ConversionRate.find(params[:id])
    log_activity(@conversion_rate)
    @conversion_rate.destroy
    flash[:notice] = "Successfully deleted conversion rate."
    redirect_to app_currency_conversion_rates_path(:app_id => @app.id, :currency_id => @currency.id)
  end

  def example
    @page_title = "Example Conversion Structure"
    @example_graph = HighchartsGraph.example_conversion_rates_graph
  end

  private

  def setup
    @app = App.find(params[:app_id])
    @currency = Currency.find(params[:currency_id])
    @conversion_rates = @currency.conversion_rates(:order => 'minimum_offerwall_bid')
  end

  def generate_graph
    graph_data = []
    if @conversion_rates.present?
      @conversion_rates.each_with_index do |rate, index|
        if graph_data.present?
          graph_data << add_to_graph(@conversion_rates[index - 1].bid_number_to_currency, rate.bid_number_to_currency, @conversion_rates[index-1].rate)
        else
          graph_data << add_to_graph(index, rate.bid_number_to_currency, @currency.conversion_rate)
        end
      end
      graph_data << add_to_graph(@conversion_rates.last.bid_number_to_currency, @conversion_rates.last.bid_number_to_currency(true), @conversion_rates.last.rate)
    else
      graph_data << add_to_graph(0, 100, @currency.conversion_rate)
    end
    @graph = HighchartsGraph.generate_graph(graph_data, "Conversion Rates Graph Layout", "Minimum Offer Payout", "Conversion Rate", 'area', false, false)
  end

  def add_to_graph(x1, x2, y)
    [[x1,y],[x2,y]] #intepretation of data from Highcharts to create a step-like graph
  end

  def error
    @conversion_rate.errors[:base].first
  end
end
