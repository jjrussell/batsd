class PurchaseVgController < ApplicationController
  
  def index
    return unless verify_params([:app_id, :udid, :virtual_good_id], {:allow_empty => false})
    
    #TO REMOVE: hackey stuff for doodle buddy, remove on Jan 1, 2011
    doodle_buddy_holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    doodle_buddy_regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    params[:app_id] = doodle_buddy_regular_id if params[:app_id] == doodle_buddy_holiday_id
    
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
