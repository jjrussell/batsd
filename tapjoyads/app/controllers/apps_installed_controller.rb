class AppsInstalledController < ApplicationController

  def index
    lookup_udid
    return unless verify_params([:app_id, :udid, :library_version, :package_names, :sdk_type, :verifier])

    unless sdkless_support?
      @error_message = "sdkless not supported"
      render :template => 'layouts/error' and return
    end

    verifier = generate_verifier([ params[:package_names] ])
    unless params[:verifier] == generate_verifier([ params[:package_names] ])
      @error_message = "invalid verifier; should be #{verifier}"
      #@error_message = "invalid verifier"
      render :template => 'layouts/error' and return
    end

    device = Device.new(:key => params[:udid])
    temp_sdkless_clicks = device.sdkless_clicks

    params[:package_names].split(',').each do |package_name|
      sdkless_click = temp_sdkless_clicks[package_name]
      if sdkless_click.present?
        click = Click.new(:key => "#{params[:udid]}.#{sdkless_click[item_id]}", :consistent => params[:consistent])

        message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
        Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)

        temp_sdkless_clicks.delete package_name
      end
    end

    device.sdkless_clicks = temp_sdkless_clicks
    device.save

    web_request = WebRequest.new
    web_request.put_values('apps_installed', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    web_request.save

    render :nothing => true
  end
end
