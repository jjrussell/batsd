class ConnectController < ApplicationController
  include DownloadContent
  include TimeLogHelper
  include RightAws
  
  def index
    return unless verify_params([:app_id, :udid, :device_type, :app_version, :device_os_version, :library_version])
    
    udid = params[:udid]
    
    #add this app to the device list
    time_log("Check conversions and maybe add to sqs") do
      click = StoreClick.new("#{params[:udid]}.#{params[:app_id]}")
      unless (click.attributes.empty? || click.get('installed'))
        logger.info "Added conversion to sqs queue"
        message = {:udid => params[:udid], :app_id => params[:app_id], 
            :install_date => Time.now.to_f.to_s}.to_json
        SqsGen2.new.queue(QueueNames::CONVERSION_TRACKING).send_message(message)
      end
    end
    
    device_app = DeviceAppList.new(params[:udid])
    unless device_app.get('app.' + params[:app_id])
      device_app.put('app.' + params[:app_id],  Time.now.utc.to_f.to_s)
      device_app.save
    end

    web_request = WebRequest.new('connect')
    web_request.put('app_id', params[:app_id])
    web_request.put('udid', udid)
    web_request.put('app_version', params[:app_version])
    web_request.put('device_os_version', params[:device_os_version])
    web_request.put('device_type', params[:device_type])
    web_request.put('library_version', params[:library_version])
    web_request.put('ip_address', request.remote_ip)
  
    web_request.save
  
    render :template => 'layouts/success'
  end
end
