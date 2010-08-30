class HomepageController < WebsiteController
  def index
    redirect_to login_path
  end
end
