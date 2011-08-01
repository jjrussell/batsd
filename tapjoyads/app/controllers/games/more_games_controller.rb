class Games::MoreGamesController < GamesController

  def index
    @editors_picks = EditorsPick.cached_active
    if params[:ajax] == '1'
      render :layout => false, :template => 'games/more_games/editor_picks_ajax'
    else
      render 'games/more_games/editor_picks'
    end
  end
  
end