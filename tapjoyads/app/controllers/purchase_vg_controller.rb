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
    
    render :template => 'layouts/tcro'
  rescue KeyExists
    num_retries = num_retries.nil? ? 1 : num_retries + 1
    if num_retries > 3
      raise "Too many retries"
    end
    sleep(0.1)
    retry
  rescue RightAws::AwsError
    @message = "Error contacting backend datastore"
    @success = false
    render :template => 'layouts/tcro'
  rescue BalanceTooLowError, UnknownVirtualGood, TooManyPurchases => e
    @message = e.to_s
    @success = false
    render :template => 'layouts/tcro'
  end
  
  ##
  # Removes all virtual goods from a device, only if the device is a beta device.
  def remove_all
    return unless verify_params([:app_id, :udid])
    
    currency = Currency.new(:key => params[:app_id])
    raise NotABetaDevice.new unless currency.beta_devices.include?(params[:udid])
    
    lock_on_key("lock.purchase_vg.#{params[:udid]}.#{params[:app_id]}") do
      point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{params[:app_id]}")
      point_purchases.virtual_goods = {}
      point_purchases.points = currency.initial_balance
      point_purchases.serial_save(:catch_exceptions => false)
    end
    @message = "You have successfully removed all virtual goods and reset the balance for this device."
  rescue NotABetaDevice => e
    @message = "Error: #{e.to_s}"
  end
  
  private
  
  class TooManyPurchases < RuntimeError
    def to_s; "You have already purchased this item the maximum number of times"; end
  end
  class BalanceTooLowError < RuntimeError
    def to_s; "Balance too low"; end
  end
  class UnknownVirtualGood < RuntimeError;
    def to_s; "Unknown virtual good"; end
  end
  class NotABetaDevice < RuntimeError
    def to_s; "Not a beta device"; end
  end
end