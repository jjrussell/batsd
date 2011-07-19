class Games::HomepageController < GamesController

  before_filter :require_login
  
  before_filter :require_complete_gamer, :only => 'real_index'
  
  # TODO: switch this to index when we're ready to launch
  def real_index
    @device = Device.new(:key => current_gamer.udid)
    @external_publishers = ExternalPublisher.load_all_for_device(@device)
  end
  
  def index
    redirect_to games_real_index_path if current_gamer.present?
  end
  
private
  
  def require_complete_gamer
    if current_gamer.blank?
      redirect_to games_login_path 
    elsif current_gamer.udid.blank?
      redirect_to edit_games_gamer_path
    end
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
