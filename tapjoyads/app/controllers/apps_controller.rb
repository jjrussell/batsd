class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :grab_partner_apps
  before_filter :has_apps, :only => [:show, :index, :integrate, :publisher_integrate]
  before_filter :find_app, :only => [:show, :index, :integrate, :publisher_integrate, :update, :confirm]
  before_filter :deprecation_notice, :only => [:integrate, :publisher_integrate]
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def index
    redirect_to @app
  end

  def new
    @app = App.new
  end

  def search
    if params[:term].present?
      params[:platform] ||= "iphone"
      results = AppStore.search(params[:term], params[:platform].downcase)
      render :json => results
    end
  end

  def show
    now = Time.zone.now
    start_time = now.beginning_of_hour - 23.hours
    end_time = now
    granularity = :daily
    stats = Appstats.new(@app.id, { :start_time => start_time, :end_time => end_time, :granularity => granularity, :stat_types => [ 'logins' ] }).stats
    @integrated = stats['logins'].sum > 0
  end

  def create
    @app = App.new
    log_activity(@app)
    
    @app.partner = current_partner
    @app.platform = params[:app][:platform]
    @app.store_id = params[:app][:store_id]
    @app.name = params[:app][:name]
    @app.fill_app_store_data
    
    if @app.save
      flash[:notice] = 'App was successfully created.'
      redirect_to(@app)
    else
      flash[:error] = 'Your app was not created.'
      render :action => "new"
    end
  end

  def update
    log_activity(@app)
    
    @app.name = params[:app][:name]
    @app.store_id = params[:app][:store_id]
    @app.fill_app_store_data
    
    if @app.save
      flash[:notice] = 'App was successfully updated.'
      redirect_to(@app)
    else
      flash[:error] = 'Update unsuccessful.'
      render :action => "show"
    end
  end

  def sdk_download
    return if params[:sdk].nil?
    if params[:android] == 'true'
      file_name = "tapjoy_sdk_android_#{params[:sdk]}.zip"
    else
      file_name = "tapjoy_sdk_#{params[:sdk]}.zip"
    end
    bucket = S3.bucket(BucketNames::APP_DATA)
    data = bucket.get("sdks/#{file_name}")
    send_data(data, :type => 'application/zip', :filename => file_name)
  end

private
  def grab_partner_apps
    session[:last_shown_app] ||= current_partner_apps.first.id unless current_partner_apps.empty?
  end

  def find_app
    @app = current_partner.apps.find_by_id(params[:id] || session[:last_shown_app])
    if @app.nil?
      session[:last_shown_app] = nil if params[:id].nil?
      redirect_to apps_path
    else
      session[:last_shown_app] = @app.id
    end
  end

  def has_apps
    redirect_to new_app_path if current_partner_apps.empty?
  end

  def deprecation_notice
    # TODO: after 2010-11-15, we should just remove this
    if Time.now.to_i < 1288828800 # 2010-11-04 UTC
      # don't display for new users
      if current_user.created_at.to_i < 1286150400 # 2010-10-04 UTC
        @deprecation_notice = 'App Password and App Version have been deprecated in the new Tapjoy system.'
      end
    end
  end
end
