class Games::MoreGamesController < GamesController
  layout false

  def editor_picks

    if using_android?
      @editors_picks = EditorsPick.cached_active('android')
    else
      @editors_picks = EditorsPick.cached_active('iphone')
    end
  end

  def recommended
    current_recommendations
  end

end
