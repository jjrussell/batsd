class ConnectController < ApplicationController

  def index
    lookup_udid
    return unless verify_params([:app_id, :udid])

    click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}", :consistent => params[:consistent], :add_to_conversion_queue => true)

    web_request = WebRequest.new
    web_request.put_values('connect', params, ip_address, geoip_data, request.headers['User-Agent'])

    device = Device.new(:key => params[:udid])
    path_list = device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      web_request.path = path
    end

    if sdkless_support?
      @sdkless_clicks = device.sdkless_clicks
    end

    web_request.save
  end
end
