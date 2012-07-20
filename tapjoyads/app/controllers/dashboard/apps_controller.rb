class Dashboard::AppsController < Dashboard::DashboardController
  layout 'apps'

  current_tab :apps

  filter_access_to :all
  before_filter :grab_partner_apps
  before_filter :has_apps, :only => [:show, :index, :integrate, :publisher_integrate, :integrate_check]
  before_filter :setup, :only => [:show, :index, :integrate, :publisher_integrate, :integrate_check, :update, :confirm, :archive, :unarchive ]
  before_filter :nag_user_about_payout_info, :only => [:show]
  after_filter :save_activity_logs, :only => [ :update, :create, :archive, :unarchive ]

  def index
    redirect_to @app
  end

  def new
    @app = App.new
    @app.platform = 'iphone'
    @store_options = AppStore.android_store_options
  end

  def search
    if params[:term].present?
      begin
        platform = params[:platform]
        case platform.downcase
        when 'windows'
          country = params[:language]
        when 'iphone'
          country = params[:country]
        when 'android'
          store_name = params[:store_name]
        end
        render :json => AppStore.search(params[:term], platform, store_name, country)
      rescue
        render :json => { :error => true }
      end
    end
  end

  def show
    @integrated = @app.primary_offer.integrated?
    @store_options = AppStore.android_store_options if @app.platform == 'android'
    flash.now[:error] = "You are looking at a deleted app." if @app.hidden?
  end

  def create
    @app = App.new
    log_activity(@app)

    @app.partner = current_partner
    @app.platform = params[:app][:platform]
    @app.name = params[:app][:name]

    if params[:state] == 'live' && params[:store_id].present?
      store_name = params[:android_store_name] if params[:android_store_name] && @app.platform == 'android'
      store_name ||= App::PLATFORM_DETAILS[@app.platform][:default_store_name]
      unless app_metadata = @app.add_app_metadata(store_name, params[:store_id], true)
        flash.now[:error] = 'Failed to create primary distribution.'
        render :action => "new" and return
      end

      begin
        app_metadata.update_from_store(params[:country])
      rescue
        flash.now[:error] = "Grabbing app data from app store failed. Please try again."
        render :action => "new" and return
      end
    end

    if @app.save
#      @app.download_icon(app_store_data[:icon_url])
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
    @app.protocol_handler = params[:app][:protocol_handler] if permitted_to? :edit, :dashboard_statz

    if params[:state] == 'live' && params[:store_id].present?
      store_name = @app.store_name || params[:android_store_name] || App::PLATFORM_DETAILS[@app.platform][:default_store_name]
      app_metadata = if @app.app_metadatas.find_by_store_name(store_name)
        @app.update_app_metadata(store_name, params[:store_id])
      else
        @app.add_app_metadata(store_name, params[:store_id], true)
      end

      unless app_metadata.present?
        flash.now[:error] = 'Failed to update primary distribution.'
        render :action => "show" and return
      end

      begin
        app_metadata.update_from_store(params[:country])
      rescue
        flash.now[:error] = "Grabbing app data from app store failed. Please try again."
        render :action => "show" and return
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

  def integrate
  end

  def publisher_integrate
  end

  def integrate_check
    if params[:udid].present? && params[:mac_address].present?
      # TODO: replace with Vertica check
      mac = params[:mac_address].downcase.gsub(/[:\s]/, '')
      @device = Device.new :key => params[:udid].downcase
      @matched = @device.mac_address.to_s == mac
    elsif params[:udid].present? || params[:mac_address].present?
      @device = Device.new
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
