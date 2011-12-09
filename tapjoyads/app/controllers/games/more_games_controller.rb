class Games::MoreGamesController < GamesController
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
    @cell_download_limit_bytes = 20.megabytes #get_cell_download_limit_bytes
  end
  
  def get_cell_download_limit_bytes
    case device_type
    when /ip/
      App::PLATFORM_DETAILS['iphone'][:cell_download_limit_bytes]
    when 'windows'
      App::PLATFORM_DETAILS['windows'][:cell_download_limit_bytes]
    else
      nil
    end
  end
end
