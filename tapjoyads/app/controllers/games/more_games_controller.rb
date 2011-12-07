class Games::MoreGamesController < GamesController
  PLATFORM_3G_DOWNLOAD_LIMIT_BYTES = {
    'iphone' => 20971520, #20mb
    'ipod' => 20971520,
    'ipad' => 20971520,
    'windows' => 20971520
  }

  layout false
  before_filter :setup

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

private

  def setup
    @platform_3g_download_limit = PLATFORM_3G_DOWNLOAD_LIMIT_BYTES[device_type]
  end
end
