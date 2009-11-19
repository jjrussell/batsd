class GetDeviceAppListController < ApplicationController
  
  def index
    device = DeviceAppList.new(params[:udid])
    
    render :text => device.attributes.to_json
  end
  
end
