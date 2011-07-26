class Games::HomepageController < GamesController
  
  before_filter :require_complete_gamer, :except => 'index' 
  
  def index
    if current_gamer.present?
      redirect_to games_real_index_path 
    else 
      render :layout => false, :template => 'games/homepage/index'
    end
  end

  def real_index
    @device = Device.new(:key => current_gamer.udid)
    @external_publishers = ExternalPublisher.load_all_for_device(@device)
    if @external_publishers.empty?
      redirect_to games_editors_picks_path
    end
  end

private

  def require_complete_gamer
    if current_gamer.blank?
      redirect_to games_login_path
    elsif current_gamer.udid.blank?
      render :template => 'games/register_device'
    end
  end


end
