class Games::MoreGamesController < GamesController

  layout false

  def editor_picks
    @editors_picks = EditorsPick.cached_active
  end
  
  def popular
    
  end

end