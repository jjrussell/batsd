# TO REMOVE - when we're sure it isn't being used

class GetDeviceAppListController < ApplicationController
  
  def index
    device = Device.new(:key => params[:udid])
    
    w = WebRequest.new
    w.put_values('get_device_app_list', params, get_ip_address, get_geoip_data)
    w.save
    
    render :text => device.attributes.to_json
  end
  
end
