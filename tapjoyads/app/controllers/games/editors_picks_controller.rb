class Games::EditorsPicksController < GamesController

  def index
    @editors_picks = EditorsPick.cached_active
  end

end
