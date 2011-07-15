class SetPublisherUserIdController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid, :publisher_user_id])
    
    device = Device.new(:key => params[:udid])
    device.set_publisher_user_id!(params[:app_id], params[:publisher_user_id])
    
    # web_request = WebRequest.new
    # web_request.put_values('set_publisher_user_id', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    # web_request.save
    
    render :template => 'layouts/success'
  end
end