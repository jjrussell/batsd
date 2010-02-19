class GetVgStoreItemsController < ApplicationController
  include MemcachedHelper

  ##
  # All virtual goods that are available to be purchased for this app from this device.
  def all
    return unless verify_params([:app_id, :udid])
    
    setup
    
    @virtual_good_list.reject! do |virtual_good|
      # TODO: don't reject items if they are allowed to be purchased multiple times.
      @point_purchases.get_virtual_good_quantity(virtual_good.key) > 0
    end
    
    @virtual_good_list = @virtual_good_list[params[:start], params[:max]] || []
  end
  
  ##
  # All virtual goods that have been purchased for this app from this device.
  def purchased
    return unless verify_params([:app_id, :udid])
    
    setup
    
    @virtual_good_list.reject! do |virtual_good|
      @point_purchases.get_virtual_good_quantity(virtual_good.key) == 0
    end
    
    @virtual_good_list = @virtual_good_list[params[:start], params[:max]] || []
  end
  
  private
  
  def setup
    @point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{params[:app_id]}")
    @currency = Currency.new(:key => params[:app_id])
    
    @virtual_good_list = get_from_cache_and_save("virtual_good_list.#{params[:app_id]}", false, 5.minutes) do
      list = []
      VirtualGood.select(:where => "app_id='#{params[:app_id]}' and disabled != '1' and beta != '1'") do |item|
        list.push(item)
      end
      list
    end
    
    if @currency.beta_devices.contains?(params[:udid])
      @virtual_good_list = @virtual_good_list | get_from_cache_and_save("virtual_good_list.beta.#{params[:app_id]}", false, 5.minutes) do
        list = []
        VirtualGood.select(:where => "app_id='#{params[:app_id]}' and disabled != '1' and beta = '1'") do |item|
          list.push(item)
        end
        list
      end
    end
  end
  
end