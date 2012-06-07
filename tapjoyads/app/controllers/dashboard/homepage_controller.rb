class Dashboard::HomepageController < Dashboard::DashboardController
  filter_access_to :team

  def index
    if has_role_with_hierarchy?(:admin)
      redirect_to tools_path
    elsif permitted_to?(:index, :dashboard_statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :dashboard_apps)
      redirect_to apps_path
    else
      redirect_to login_path
    end
  end

  def team
    @employees = Employee.active_by_first_name
    url = 'http://www.badjrr.com/api.json?api_key=business1'
    @badges = {}

    tries = 0
    begin
      badges = JSON.load(Downloader.get(url))
    rescue
      tries += 1
      retry unless tries > 5
    end

    (badges || []).each do |badge|
      @badges[badge['user_email']] ||= []
      @badges[badge['user_email']] << badge
    end
    render :layout => 'dashboard'
  end
end
