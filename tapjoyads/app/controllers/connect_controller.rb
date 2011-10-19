class ConnectController < ApplicationController

  def index
    return unless verify_params([:app_id, :udid])

    # TO REMOVE: when textfree turns off their server-to-server pings
    # textfree is integrated and sending server-to-server pings so we'll ignore the server-to-server pings
    if params[:app_id] == '6b69461a-949a-49ba-b612-94c8e7589642' && params[:ConnectLibraryVersion].present?
      return
    end

    click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}")
    if click.rewardable?
      message = { :click => click.serialize(:attributes_only => true), :install_timestamp => Time.zone.now.to_f.to_s }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end

    web_request = WebRequest.new
    web_request.put_values('connect', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])

    device = Device.new(:key => params[:udid])
    path_list = device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      web_request.path = path
    end

    web_request.save
  end
end
