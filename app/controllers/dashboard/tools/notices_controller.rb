class Dashboard::Tools::NoticesController < Dashboard::DashboardController
  layout 'tabbed'

  def index
    flash.now[:warn] = "BE CAREFUL. This is real HTML. If you forget to close a tag, you can wreck the dashboard and RUIN CHRISTMAS for EVERYONE."
  end

  def update
    product_notice.message = params[:message]
    redirect_to :action => :index
  end
end
