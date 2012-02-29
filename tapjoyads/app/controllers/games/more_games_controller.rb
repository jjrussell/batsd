class Games::MoreGamesController < GamesController

  def editor_picks
    current_gamer
    if using_android?
      @editors_picks = EditorsPick.cached_active('android')
    else
      @editors_picks = EditorsPick.cached_active('iphone')
    end
  end

  def recommended
    current_gamer
    current_recommendations
  end

end
