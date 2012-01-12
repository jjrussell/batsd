class Tools::NetworkCostsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :create ]

  def index
    @costs = NetworkCost.all
    @current_costs = NetworkCost.for_date(Date.today).sum(:amount)
  end

  def new
    @network_cost = NetworkCost.new
  end

  def create
    network_cost_params = sanitize_currency_params(params[:network_cost], [ :amount ])
    @network_cost = NetworkCost.new(network_cost_params)
    log_activity(@network_cost)
    if @network_cost.save
      flash[:notice] = 'Saved successfully.'
      redirect_to :action => :index
    else
      render :new
    end
  end

end
