class PurchaseVgController < ApplicationController
  
  def index
    return unless verify_params([:app_id, :udid, :virtual_good_id], {:allow_empty => false})
    
    publisher_user_id = params[:udid]
    publisher_user_id = params[:publisher_user_id] unless params[:publisher_user_id].blank?
    
    @success, @message = PointPurchases.purchase_virtual_good("#{publisher_user_id}.#{params[:app_id]}", params[:virtual_good_id])
    
    if @success
      web_request = WebRequest.new
      web_request.put_values('purchased_vg', params, get_ip_address, get_geoip_data)
      web_request.save
    end
    
    render :template => 'layouts/tcro'
  end
end
