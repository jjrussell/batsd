class Dashboard::VideosController < Dashboard::DashboardController

  layout 'apps'
  current_tab :apps
  before_filter :setup
  filter_access_to :all

  def index
    #placeholder for future use
  end

  def options
  end

  def update_options
    @app.videos_enabled    = params[:app][:videos_enabled]
    @app.videos_cache_mode = params[:app][:videos_cache_mode]
    @app.videos_cache_wifi = params[:app][:videos_cache_wifi]
    @app.videos_cache_3g   = params[:app][:videos_cache_3g]
    @app.videos_stream_3g  = params[:app][:videos_stream_3g]

    if @app.save
      render :json => {:success => true}, :status => :ok
    else
      render :json => {:success => false}, :status => :unprocessable_entity
    end
  end

  private

  def setup
    @app = find_app(params[:app_id])
  end

end
