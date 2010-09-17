class HomepageController < WebsiteController
  def index
    if current_user.nil?
      redirect_to login_path
    elsif permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    end
  end
end
