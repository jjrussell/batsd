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
      redirect_to games_more_games_path
    end
  end

  def more_games
    @device = Device.new(:key => current_gamer.udid)
    @external_publishers = ExternalPublisher.load_all_for_device_filter_installed(@device)
    if params[:ajax] == '1'
      render :layout => false, :template => 'games/homepage/more_games_ajax'
    else
      render :template => 'games/homepage/more_games'
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
