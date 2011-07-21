class Games::EditorsPicksController < GamesController

  def index
    @editors_picks = EditorsPick.active.first(10)
  end

end
