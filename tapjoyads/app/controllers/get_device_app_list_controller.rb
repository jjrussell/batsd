# TO REMOVE - when we're sure it isn't being used

class GetDeviceAppListController < ApplicationController
  
  def index
    device = Device.new(:key => params[:udid])
    
    render :text => device.attributes.to_json
  end
  
end
