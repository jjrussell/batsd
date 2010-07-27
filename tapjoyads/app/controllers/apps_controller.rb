class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_apps

  def index
    @app_data =
      unless @my_apps.blank?
        @my_apps.first.to_json(:include => {
          :offer => {
            :methods => [:get_icon_url ]
          }
        })
      end
  end

  def show
    respond_to do |format|
      format.html { redirect_to apps_path }
      format.json do
        app = App.find(params[:id])
        app = nil unless @my_apps.include?(app)
        render :json => app.to_json(:include => {
            :offer => {
              :methods => [:get_icon_url ]
            }
          },
          :methods => [:store_url])
      end
    end
  end

  private
    def get_apps
      @my_apps = current_partner.apps
    end
end
