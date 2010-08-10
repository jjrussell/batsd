class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :grab_partner_apps

  def index
    @app = current_partner_apps.first
    render :action => "show"
  end

  def show
    @app = App.find(params[:id])
  end

  def update
    @app = App.find(params[:id])

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
  end
end
