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
  
      point_purchases.add_virtual_good(virtual_good.key)
      
      point_purchases.points = point_purchases.points - virtual_good.price
      raise BalanceTooLowError.new if point_purchases.points < 0
  
      point_purchases.serial_save(:catch_exceptions => false)
      
      @message = "You successfully purchased #{virtual_good.name}"
    end
    
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
  end
  
  private
  
  class BalanceTooLowError < RuntimeError; end
  class UnknownVirtualGood < RuntimeError; end
end