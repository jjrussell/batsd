class AppsController < WebsiteController
  layout 'apps'

  filter_access_to :all
  before_filter :grab_partner_apps
  before_filter :has_apps, :only => [:show, :index, :integrate, :publisher_integrate]
  before_filter :setup, :only => [:show, :index, :integrate, :publisher_integrate, :update, :confirm, :archive, :unarchive ]
  before_filter :nag_user_about_payout_info, :only => [:show]
  after_filter :save_activity_logs, :only => [ :update, :create, :archive, :unarchive ]

  def index
    redirect_to @app
  end

  def new
    @app = App.new
    @app.platform = 'iphone'
  end

  def search
    if params[:term].present?
      begin
        results = AppStore.search(params[:term], params[:platform], params[:country])
        render :json => results
      rescue
        render :json => { :error => true }
      end
    end
  end

  def show
    @integrated = @app.primary_offer.integrated?
    flash.now[:error] = "You are looking at a deleted app." if @app.hidden?
  end

  def create
    @app = App.new
    log_activity(@app)

    @app.partner = current_partner
    @app.platform = params[:app][:platform]
    @app.name = params[:app][:name]

    app_store_data = {}
    if params[:state] == 'live' && params[:app][:store_id].present?
      unless @app.update_from_store({ :store_id => params[:app][:store_id], :country => params[:app_country] })
        flash.now[:error] = "Grabbing app data from app store failed. Please try again."
        render :action => "new"
        return
      end
    end

    if @app.save
      @app.download_icon(app_store_data[:icon_url])
      flash[:notice] = 'App was successfully created.'
      redirect_to(@app)
    else
      flash.now[:error] = 'Your app was not created.'
      render :action => "new"
    end
  end

  def update
    log_activity(@app)

    @app.name = params[:app][:name]

    if params[:state] == 'live' && params[:app][:store_id].present?
      unless @app.update_from_store({ :store_id => params[:app][:store_id], :country => params[:app_country] })
        flash.now[:error] = "Grabbing app data from app store failed. Please try again."
        render :action => "show"
        return
      end
    end

    if @app.save
      flash[:notice] = 'App was successfully updated.'
      redirect_to(@app)
    else
      flash.now[:error] = 'Update unsuccessful.'
      render :action => "show"
    end
  end

  def archive
    if @app.offers.any?{|o| o.is_enabled?}
      flash[:error] = "Apps cannot be deleted until all offers are disabled"
      redirect_to(@app)
      return
    end
    log_activity(@app)
    @app.hidden = true
    if @app.save
      flash[:notice] = "App #{@app.name} was successfully deleted."
      session[:last_shown_app] = nil
      redirect_to(apps_path)
    else
      flash[:error] = "Your app #{@app.name} could not be deleted."
      redirect_to(@app)
    end
  end

  def unarchive
    log_activity(@app)
    @app.hidden = false
    if @app.save
      flash[:notice] = "App #{@app.name} was successfully undeleted."
      session[:last_shown_app] = @app.id
      redirect_to(@app)
    else
      flash[:error] = "App #{@app.name} could not be undeleted."
      redirect_to(@app)
    end
  end

  private

  def grab_partner_apps
    session[:last_shown_app] ||= current_partner_apps.first.id unless current_partner_apps.empty?
  end

  def setup
    @app = find_app(params[:id] || session[:last_shown_app])
    session[:last_shown_app] = @app.id
  end

  def has_apps
    redirect_to new_app_path if current_partner_apps.empty?
  end
end
