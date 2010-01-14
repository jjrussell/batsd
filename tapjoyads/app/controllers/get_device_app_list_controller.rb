class GetDeviceAppListController < ApplicationController
  
  def index
    device = DeviceAppList.new(:key => params[:udid])
    
    render :text => device.attributes.to_json
  end
  
end
