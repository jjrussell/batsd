class AdshownController < ApplicationController
  before_filter :lookup_device

  def index
    return unless verify_params([:campaign_id, :app_id]) && verify_records(get_device_key)

    web_request = WebRequest.new
    web_request.put_values('adshown', params, ip_address, geoip_data, request.headers['User-Agent'])
    web_request.save

    render :template => 'layouts/success'
  end
end
