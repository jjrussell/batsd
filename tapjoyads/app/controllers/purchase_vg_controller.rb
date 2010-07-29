class PurchaseVgController < ApplicationController
  
  def index
    return unless verify_params([:app_id, :udid, :virtual_good_id], {:allow_empty => false})
    
    @success, @message = PointPurchases.purchase_virtual_good("#{params[:udid]}.#{params[:app_id]}", params[:virtual_good_id])
    
    if @success
      web_request = WebRequest.new
      web_request.put_values('purchased_vg', params, get_ip_address, get_geoip_data)
      web_request.save
    end
    
    render :template => 'layouts/tcro'
  end
  
  ##
  # Removes all virtual goods from a device, only if the device is a beta device.
  def remove_all
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    currency = Currency.find_in_cache_by_app_id(params[:app_id])
    raise NotABetaDevice.new unless currency.get_test_device_ids.include?(params[:udid])
    
    PointPurchases.transaction(:key => "#{params[:udid]}.#{params[:app_id]}") do |point_purchases|
      point_purchases.virtual_goods = {}
      point_purchases.points = currency.initial_balance
    end
    @message = "You have successfully removed all virtual goods and reset the balance for this device."
  rescue NotABetaDevice => e
    @message = "Error: #{e.to_s}"
  end
  
private
  
  class NotABetaDevice < RuntimeError
    def to_s; "Not a beta device"; end
  end
end