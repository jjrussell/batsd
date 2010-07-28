class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all
  before_filter :get_apps

  def index
    @apps_data = @my_apps.map(&:to_json_with_offer)
  end

  private
    def get_apps
      @my_apps = current_partner.apps
    end
end
