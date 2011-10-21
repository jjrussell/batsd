class Tools::ExternalPublishersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :update ]

  def index
    @num_tapjoy_enabled = Currency.tapjoy_enabled.count
    @num_external_pubs = Currency.external_publishers.count
    @currencies = Currency.find_all_by_tapjoy_enabled(true, :include => [:app, :partner])
  end

  def update
    currency = Currency.find(params[:id])
    log_activity(currency)
    currency.external_publisher = !currency.external_publisher
    if currency.save
      ExternalPublisher.cache
      flash[:notice] = "Currency updated"
      redirect_to tools_external_publishers_path
    else
      flash[:error] = "Error updating currency"
      redirect_to tools_external_publishers_path
    end
  end

end
