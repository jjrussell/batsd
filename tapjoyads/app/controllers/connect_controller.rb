class ConnectController < ApplicationController

  def index
    params[:app_id] = '7e81549a-7fc5-4940-9435-11371ee47fa9' if request.headers['User-Agent'] =~ /DeerHunting/
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    @country = nil
    
    #add this app to the device list
    Rails.logger.info_with_time("Check conversions and maybe add to sqs") do
      click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      unless (click.attributes.empty? || click.installed_at)
        @country = click.country if click.clicked_at > (Time.zone.now - 2.days)
        logger.info "Added conversion to sqs queue"
        message = { :click => click.serialize(:attributes_only => true), :install_timestamp => Time.zone.now.to_f.to_s }.to_json
        Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
      end
    end
    
    web_request = WebRequest.new
    web_request.put_values('connect', params, get_ip_address, get_geoip_data)
    
    device_app_list = Device.new(:key => params[:udid])
    path_list = device_app_list.set_app_ran(params[:app_id], params)
    path_list.each do |path|
      web_request.add_path(path)
    end
    
    device_app_list.save
    
    @app = App.find_in_cache(params[:app_id], false)
    
    web_request.save
  
  end
end
