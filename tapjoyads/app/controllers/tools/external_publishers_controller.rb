class Tools::ExternalPublishersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  
  after_filter :save_activity_logs, :only => [ :update ]
  
  def index
    @currencies = Currency.potential_external_publishers
  end
  
  def update
    currency = Currency.find(params[:id])
    log_activity(currency)
    currency.external_publisher = !currency.external_publisher
    if currency.save
      ExternalPublishers.cache
      flash[:notice] = "Currency updated"
      redirect_to tools_external_publishers_path
    else
      flash[:error] = "Error updating currency"
      redirect_to tools_external_publishers_path 
    end
  end
  
end