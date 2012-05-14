class Apps::VideosController < WebsiteController

  layout 'apps'
  current_tab :apps
  before_filter :setup
  filter_access_to :all

  def index
    #placeholder for future use
  end
  
  private

  def setup
    @app = find_app(params[:app_id])
  end

end