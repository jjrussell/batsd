class Dashboard::HomepageController < Dashboard::DashboardController

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

end
