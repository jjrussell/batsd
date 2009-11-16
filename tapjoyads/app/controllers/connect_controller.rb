require 'activemessaging/processor'

class ConnectController < ApplicationController
  include ActiveMessaging::MessageSender
    
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END
  
    if ((not params[:app_id]) || (not params[:udid]) || (not params[:device_type]) ||
      (not params[:app_version]) || (not params[:device_os_version]) || (not params[:library_version]) )
      error = Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    udid = params[:udid]
    
    #add this app to the device list
    Thread.new do
      device = DeviceAppList.new(udid)
      unless device.get(params[:app_id])
        device.add_app(params[:app_id])
      end
    end
    

    now = Time.now
  
    web_request = WebRequest.new('connect')
    web_request.put('app_id', params[:app_id])
    web_request.put('udid', udid)
    web_request.put('app_version', params[:app_version])
    web_request.put('device_os_version', params[:device_os_version])
    web_request.put('device_type', params[:device_type])
    web_request.put('library_version', params[:library_version])

    web_request.put('ip_address', request.remote_ip)
  
    logger.info "Created WebRequest object (#{Time.now - now}s)"
    now = Time.now
  
    Thread.new do
      start_time = Time.now
      web_request.save
      logger.info "WebRequest sdb save (#{Time.now - start_time}s)"
      logger.flush
    end
  
    logger.info "Spawned thread (#{Time.now - now}s)"
  
    respond_to do |f|
      f.xml {render(:text => xml)}
    end

  end
  
end
