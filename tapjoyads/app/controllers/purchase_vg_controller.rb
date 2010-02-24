class PurchaseVgController < ApplicationController
  include MemcachedHelper
  include NewRelicHelper
  
  def index
    return unless verify_params([:app_id, :udid, :virtual_good_id])
    
    lock_on_key("lock.purchase_vg.#{params[:udid]}.#{params[:app_id]}") do
      virtual_good = VirtualGood.new(:key => params[:virtual_good_id])
      point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      raise UnknownVirtualGood.new if virtual_good.is_new
      
      Rails.logger.info "Purchasing virtual good for price: #{virtual_good.price}, from user balance: #{point_purchases.points}"
  
      raise TooManyPurchases.new if point_purchases.get_virtual_good_quantity(virtual_good.key) >= virtual_good.max_purchases
      point_purchases.add_virtual_good(virtual_good.key)
      
      point_purchases.points = point_purchases.points - virtual_good.price
      raise BalanceTooLowError.new if point_purchases.points < 0
  
      point_purchases.serial_save(:catch_exceptions => false)
      
      @message = "You successfully purchased #{virtual_good.name}"
    end
    
    web_request = WebRequest.new
    web_request.put_values('purchased_vg', params, request)
    web_request.save
    
    render :template => 'layouts/success'
  rescue KeyExists
    num_retries = num_retries.nil? ? 1 : num_retries + 1
    if num_retries > 3
      raise "Too many retries"
    end
    sleep(0.1)
    retry
  rescue RightAws::AwsError
    @error_message = "Error contacting backend datastore"
    render :template => 'layouts/error'
  rescue BalanceTooLowError
    @error_message = "Balance too low"
    render :template => 'layouts/error'
  rescue UnknownVirtualGood
    @error_message = "Unknown virtual good"
    render :template => 'layouts/error'
  rescue TooManyPurchases
    @error_message = "You have already purchased this item the maximum number of times"
    render :template => 'layouts/error'
  end
  
  ##
  # Removes all virtual goods from a device, only if the device is a beta device.
  def remove_all
    return unless verify_params([:app_id, :udid])
    
    currency = Currency.new(:key => params[:app_id])
    raise NotABetaDevice.new unless currency.beta_devices.include?(params[:udid])
    
    point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{params[:app_id]}")
    point_purchases.virtual_goods = {}
    point_purchases.serial_save(:catch_exceptions => false)
    
    render :template => 'layouts/success'
  rescue NotABetaDevice
    @error_message = "Not a beta device"
    render :template => 'layouts/error'
  end
  
  private
  
  class TooManyPurchases < RuntimeError; end
  class BalanceTooLowError < RuntimeError; end
  class UnknownVirtualGood < RuntimeError; end
  class NotABetaDevice < RuntimeError; end
end