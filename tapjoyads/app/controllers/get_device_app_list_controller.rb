class GetDeviceAppListController < ApplicationController
  
  def index
    udid = params[:udid]
    device = DeviceAppList.new(udid)
    
    render :text => device.item.attributes.to_a.to_json
  end
  
end
