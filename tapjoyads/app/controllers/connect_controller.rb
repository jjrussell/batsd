class ConnectController < ApplicationController
  include AdminDeviceLastRun::ControllerExtensions

  tracks_admin_devices # :only => [:index]
  before_filter :reject_banned_udids
  before_filter :reject_banned_advertising_ids

  def index
    lookup_device(true)

    return unless verify_params([:app_id]) && verify_device_info

    @device = find_or_create_device(true)

    return unless verify_records(@device)

    unless @device.has_app?(params[:app_id]) && !@device.is_temporary
      click = Click.new(:key => "#{get_device_key}.#{params[:app_id]}", :consistent => params[:consistent])
      if click.new_record? && params[:mac_address].present? && params[:mac_address] != params[:udid]
        click = Click.new(:key => "#{params[:mac_address]}.#{params[:app_id]}", :consistent => params[:consistent])
      end
      if click.rewardable?
        message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
        Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
      end
    end

    # ivar for the benefit of tracks_admin_devices
    @web_request = WebRequest.new
    @web_request.put_values('connect', params, ip_address, geoip_data, request.headers['User-Agent'])
    @web_request.raw_url = request.url
    update_web_request_store_name(@web_request, params[:app_id])

    path_list = @device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      @web_request.path = path
    end

    @web_request.save

    if sdkless_supported?
      @sdkless_clicks = @device.sdkless_clicks
    end
  end
end
