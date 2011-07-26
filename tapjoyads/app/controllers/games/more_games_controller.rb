class Games::MoreGamesController < GamesController

  def index
    @editors_picks = EditorsPick.cached_active
    if params[:ajax] == '1'
      render :layout => false, :template => 'games/more_games/ajax'
    end
  end

end
