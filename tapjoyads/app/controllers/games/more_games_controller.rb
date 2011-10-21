class Games::MoreGamesController < GamesController

  layout false

  def editor_picks
    @editors_picks = EditorsPick.cached_active
  end

  def popular
    if HeaderParser.device_type(request.headers['user-agent']) == 'android'
      @popular_apps = PopularApp.get_android
    else
      @popular_apps = PopularApp.get_ios
    end
  end
end
