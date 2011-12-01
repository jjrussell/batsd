class Games::MoreGamesController < GamesController

  layout false

  def editor_picks
    if using_android?
      @editors_picks = EditorsPick.cached_active('android')
    else
      @editors_picks = EditorsPick.cached_active('iphone')
    end
  end

  def popular
    if using_android?
      @popular_apps = PopularApp.get_android
    else
      @popular_apps = PopularApp.get_ios
    end
  end

end
