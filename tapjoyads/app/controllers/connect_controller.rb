require 'sqs'
require 'queue_names'
require 'stats_cache'

class ConnectController < ApplicationController
  include AdminDeviceLastRun::ControllerExtensions

  tracks_admin_devices # :only => [:index]
  before_filter :reject_banned_udids

  def index
    lookup_udid(true)
    required_param = [:app_id]
    required_param << :udid unless params[:identifiers_provided]

    return unless verify_params(required_param)
    return unless params[:udid].present?

    @device   = Device.new({ :key => params[:udid], :is_temporary => params[:udid_is_temporary].present? })
    click     = nil
    path_list = []

    unless @device.has_app?(params[:app_id]) && !@device.is_temporary
      click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}", :consistent => params[:consistent])
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

    if click
      @web_request.click_id       =  click.id
      @web_request.click_offer_id =  click.offer_id
      path_list                   << 'conversion_user'
    end

    update_web_request_store_name(@web_request, params[:app_id])

    path_list += @device.handle_connect!(params[:app_id], params)
    path_list.each do |path|
      @web_request.path = path
    end

    begin
      @web_request.save
    rescue JSON::GeneratorError => e
      @web_request.attributes.ensure_utf8_encoding!
      @web_request.save # will re-raise the same thing if fix doesn't work
    end

    if sdkless_supported?
      @sdkless_clicks = @device.sdkless_clicks
    end
  end
end
