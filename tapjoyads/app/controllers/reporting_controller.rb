class ReportingController < WebsiteController
  layout 'tabbed'

  filter_access_to :all

  def index
    @apps_data = current_partner_apps
  end
end
