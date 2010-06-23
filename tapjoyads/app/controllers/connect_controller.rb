class ConnectController < ApplicationController
  include DownloadContent
  include TimeLogHelper
  include SqsHelper
  
  def index
    #return unless verify_params([:app_id, :udid, :device_type, :app_version, :device_os_version, :library_version])
    params[:app_id] = '7e81549a-7fc5-4940-9435-11371ee47fa9' if request.headers['User-Agent'] =~ /DeerHunting/
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    #add this app to the device list
    time_log("Check conversions and maybe add to sqs") do
      click = StoreClick.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      unless (click.attributes.empty? || click.get('installed'))
        logger.info "Added conversion to sqs queue"
        message = {:udid => params[:udid], :app_id => params[:app_id], 
            :install_date => Time.now.utc.to_f.to_s}.to_json
        send_to_sqs(QueueNames::CONVERSION_TRACKING, message)
      end
    end
    
    web_request = WebRequest.new
    web_request.put_values('connect', params, request)
    
    device_app_list = DeviceAppList.new(:key => params[:udid])
    path_list = device_app_list.set_app_ran(params[:app_id])
    path_list.each do |path|
      web_request.add_path(path)
    end
    
    device_app_list.save
    
    @app = App.find_in_cache(params[:app_id], false)
    
    web_request.save
  
  end
end
