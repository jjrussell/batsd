class Games::MoreGamesController < GamesController

  layout false

  def editor_picks
    if using_android?
      @editors_picks = EditorsPick.cached_active
    else
      @editors_picks = EditorsPick.cached_active
    end
  end

  def popular
    if using_android?
      @popular_apps = PopularApp.get_android
    else
      @popular_apps = PopularApp.get_ios
    end
  end

private

  def using_android?
    if current_gamer && current_device_id
      device = current_gamer.gamer_devices.find_by_device_id(current_device_id)
      device.device_type =~ /android/
    else
      HeaderParser.device_type(request.headers['user-agent']) == 'android'
    end
  end

end
