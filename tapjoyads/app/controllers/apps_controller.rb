class AppsController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  def index
    @apps_data = current_partner_apps.map(&:to_json_with_offer)
  end
end
