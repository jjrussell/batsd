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
    @recommendations = Device.new(:key => current_device_id).recommendations(:device_type => device_type, :geoip_data => get_geoip_data, :os_version => os_version)
  end
end