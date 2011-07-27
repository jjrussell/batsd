class Games::MoreGamesController < GamesController

  def index
    redirect_to games_editor_picks_path
  end
  
  def editor_picks
    @editors_picks = EditorsPick.cached_active
    if params[:ajax] == '1'
      render :layout => false, :template => 'games/more_games/editor_picks_ajax'
    else
      render :template => 'games/more_games/editor_picks'
    end
  end
  
  def top_games
    @device = Device.new(:key => current_gamer.udid)
    @external_publishers = ExternalPublisher.load_all_for_device_filter_installed(@device)
    if params[:ajax] == '1'
      render :layout => false, :template => 'games/more_games/top_games_ajax'
    else
      render :template => 'games/more_games/top_games'
    end 
  end
  
end