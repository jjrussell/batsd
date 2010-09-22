class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :grab_partner_apps
  before_filter :has_apps, :only => [:show, :index]
  before_filter :find_app, :only => [:show, :index, :update, :confirm]
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def index
    render :action => "show"
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

  def confirm
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
end
