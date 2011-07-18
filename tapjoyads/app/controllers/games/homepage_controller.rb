class Games::HomepageController < GamesController

  before_filter :require_login
  
  def index
  end
  
  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to access Tapjoy Games"
      redirect_to games_login_url
    end
  end
  
  def logged_in?
    !!current_gamer
  end
   
end
