class ScrapeAppsController < ApplicationController
  def index
    return unless verify_params([:udid, :all_apps])
    device = Device.new(:key => params[:udid], :consistent => true)
    if device.new_record?
      render :text => "invalid device", :status => 400
      return
    end

    web_request = WebRequest.new
    web_request.put_values('scrape_apps', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    web_request.save

    device.update_scraped_apps!(params[:all_apps])
    @new_refresh_interval = 1.week
  end
end
