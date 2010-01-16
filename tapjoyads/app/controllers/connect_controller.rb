class ConnectController < ApplicationController
  include DownloadContent
  include TimeLogHelper
  include RightAws
  
  def index
    return unless verify_params([:app_id, :udid, :device_type, :app_version, :device_os_version, :library_version])
    
    if params[:udid] == '' or params[:app_id] == ''
      log_missing_required_params
      render :text => "missing required params"
      return
    end
    
    #add this app to the device list
    time_log("Check conversions and maybe add to sqs") do
      click = StoreClick.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      unless (click.attributes.empty? || click.get('installed'))
        logger.info "Added conversion to sqs queue"
        message = {:udid => params[:udid], :app_id => params[:app_id], 
            :install_date => Time.now.to_f.to_s}.to_json
        SqsGen2.new.queue(QueueNames::CONVERSION_TRACKING).send_message(message)
      end
    end
    
    web_request = WebRequest.new
    web_request.put_values('connect', params, request)
    
    device_app_list = DeviceAppList.new(:key => params[:udid])
    unless device_app_list.has_app(params[:app_id])
      # TODO: once device_app_list is sharded, run set_app_ran on every call.
      #       Add web-requests for dau's etc..
      device_app_list.set_app_ran(params[:app_id])
      device_app_list.save
      
      web_request.add_path('new_user')
    end

    web_request.save
  
    render :template => 'layouts/success'
  end
end
