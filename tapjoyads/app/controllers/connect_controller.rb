class ConnectController < ApplicationController

  before_filter :reject_banned_udids

  def index
    lookup_udid
    required_param = [:app_id]
    required_param << :udid unless params[:identifiers_provided]

    return unless verify_params(required_param)
    return unless params[:udid].present?

    device = Device.new(:key => params[:udid])

    unless device.has_app?(params[:app_id])
      click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}", :consistent => params[:consistent])
      if click.new_record? && params[:mac_address].present? && params[:mac_address] != params[:udid]
        click = Click.new(:key => "#{params[:mac_address]}.#{params[:app_id]}", :consistent => params[:consistent])
      end
      if click.rewardable?
        message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
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
