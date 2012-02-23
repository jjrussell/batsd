class ConnectController < ApplicationController

  def index
    lookup_udid
    return unless verify_params([:app_id, :udid])

    click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}", :consistent => params[:consistent])
    if click.rewardable?
      message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end

    web_request = WebRequest.new
    web_request.put_values('connect', params, ip_address, geoip_data, request.headers['User-Agent'])

    device = Device.new(:key => params[:udid])
    path_list = device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      web_request.path = path
    end

    web_request.save

    @sdkless_supported = sdkless_supported?
    if @sdkless_supported
      @sdkless_clicks = device.sdkless_clicks
    end
  end
end
