class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :grab_partner_apps
  before_filter :has_apps, :only => [:show, :index]
  before_filter :find_app, :only => [:show, :update, :confirm]

  def index
    @app = current_partner_apps.select{|a|a.id == session[:last_shown_app]}.first
    render :action => "show"
  end

  def new
    @app = App.new
  end

  def search
    if params[:term].present?
      results = AppStore.search(params[:term], params[:platform].downcase).sort_by{|item|item[:title]}
      render :json => results
    end
  end

  def show
    now = Time.zone.now
    start_time = now.beginning_of_hour - 23.hours
    end_time = now
    granularity = :daily
    stats = Appstats.new(@app.id, { :start_time => start_time, :end_time => end_time, :granularity => granularity }).stats
    @integrated = stats['logins'].sum > 0
  end

  def create
    @app = App.new(params[:app])
    @app.partner = current_partner
    params[:app]["price"] = (params[:app]["price"].to_f * 100).to_i.to_s
    respond_to do |format|
      if @app.save
        format.html { redirect_to(confirm_app_path(@app)) }
        format.xml  { render :xml => @app, :status => :created, :location => @app }
      else
        flash[:error] = 'Your app was not created.'
        format.html { render :action => "new" }
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      params[:app]["price"] = (params[:app]["price"].to_f * 100).to_i.to_s
      if @app.update_attributes(params[:app])
        flash[:notice] = 'App was successfully updated.'
        format.html { redirect_to(@app) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Update unsuccessful.'
        format.html { render :action => "show" }
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  def confirm
  end

private
  def grab_partner_apps
    session[:last_shown_app] ||= current_partner_apps.first.id unless current_partner_apps.blank?
  end

  def find_app
    @app = current_partner.apps.find(params[:id])
    session[:last_shown_app] = @app.id
  rescue
    flash[:error] = "App not found"
    redirect_to apps_path
  end

  def has_apps
    redirect_to new_app_path if current_partner_apps.empty?
  end
end
