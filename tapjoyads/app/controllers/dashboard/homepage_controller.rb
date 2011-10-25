class Dashboard::HomepageController < WebsiteController

  def index
    if has_role_with_hierarchy?(:admin)
      redirect_to tools_path
    elsif permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    else
      redirect_to login_path
    end
  end

end
