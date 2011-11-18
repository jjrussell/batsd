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
    @recommendations = Device.new(:key => current_device_id).recommendations(:device_type => device_type, :geoip_data => geoip_data, :os_version => os_version)
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
