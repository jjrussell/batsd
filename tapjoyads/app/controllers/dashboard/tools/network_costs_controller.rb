class Dashboard::Tools::NetworkCostsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :create ]

  def index
    @costs = NetworkCost.all
  end
end
