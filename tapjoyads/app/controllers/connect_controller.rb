class ConnectController < ApplicationController
  include DownloadContent
  include TimeLogHelper
  include RightAws
  
  def index
    return unless verify_params([:app_id, :udid, :device_type, :app_version, :device_os_version, :library_version])
    
    if params[:udid] == '' or params[:app_id] == ''
      log_missing_required_params
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
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
      
      web_request = WebRequest.new('new_user', params, request)
      web_request.save
    end

    web_request = WebRequest.new('connect', params, request)
    web_request.save
  
    render :template => 'layouts/success'
  end
end
