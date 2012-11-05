class Dashboard::Tools::NoticesController < Dashboard::DashboardController
  layout 'tabbed'

  before_filter :load_notice

  def index; end

  def update
    @notice.message = params[:message]
    redirect_to :action => :index
  end

  private
  def load_notice
    @notice ||= ProductNotice.instance
  end
end
