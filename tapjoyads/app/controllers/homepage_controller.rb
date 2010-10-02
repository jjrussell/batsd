class HomepageController < WebsiteController
  layout nil
  def index
    if current_user.nil?
      redirect_to '/site/index.html'
    elsif permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    end
  end
end
