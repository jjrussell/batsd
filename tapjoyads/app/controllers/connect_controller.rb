class ConnectController < ApplicationController

  def index
    lookup_udid
    return unless verify_params([:app_id, :udid])

    device = Device.new(:key => params[:udid])

    unless device.has_app?(params[:app_id])
      click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}", :consistent => params[:consistent])
      if click.new_record? && params[:mac_address].present? && params[:mac_address] != params[:udid]
        click = Click.new(:key => "#{params[:mac_address]}.#{params[:app_id]}", :consistent => params[:consistent])
      end
      if click.rewardable?
        message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s, message[:http_request_env] = request.spoof_env }.to_json
        Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
      end
    end

    web_request = WebRequest.new
    web_request.put_values('connect', params, ip_address, geoip_data, request.headers['User-Agent'])

    path_list = device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      web_request.path = path
    end

    web_request.save

    if sdkless_supported?
      @sdkless_clicks = device.sdkless_clicks
    end
  end
end
