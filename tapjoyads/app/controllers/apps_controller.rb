class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :grab_partner_apps
  before_filter :find_app, :only => [:show, :update]

  def index
    @app = current_partner_apps.select{|a|a.id == session[:last_shown_app]}.first
    render :action => "show"
  end

  def show
  end

  def new
    @app = App.new
  end

  def create
    @app = App.new(params[:app])
    @app.partner = current_partner
    respond_to do |format|
      if @app.save
        flash[:notice] = 'Your app was successfully created.'
        format.html { redirect_to(@app) }
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

private
  def grab_partner_apps
    @apps = current_partner_apps
    session[:last_shown_app] ||= @apps.first.id unless @apps.blank?
  end

  def find_app
    @app = App.find(params[:id])
    session[:last_shown_app] = @app.id
  end
end
