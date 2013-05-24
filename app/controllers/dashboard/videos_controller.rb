class Dashboard::VideosController < Dashboard::DashboardController

  layout 'apps'
  current_tab :apps
  before_filter :setup
  before_filter :inform_of_cache_sdk_version, :only => [:options]
  filter_access_to :all

  CACHE_SDK_VERSION_NOTICE = "This page enables you to control the caching behavior for video assets on devices using
                              your publisher app. Please note these controls will <b>only</b> work on publisher apps
                              using <b>SDK versions greater than or equal to 8.3.0</b>. In apps using older SDKs,
                              caching behavior is controlled from within the SDK itself."

  def index
    #placeholder for future use
  end

  def options
  end

  def update_options
    @app.videos_enabled    = params[:app][:videos_enabled]
    @app.videos_cache_auto = params[:app][:videos_cache_auto]
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
  def inform_of_cache_sdk_version
    flash.now[:notice] = CACHE_SDK_VERSION_NOTICE if current_user.present?
  end

  def setup
    @app = find_app(params[:app_id])
  end

end
