class GetVgStoreItemsController < ApplicationController
  include MemcachedHelper

  ##
  # All virtual goods that are available to be purchased for this app from this device.
  def all
    return unless verify_params([:app_id, :udid])
    
    setup
    
    @virtual_good_list.reject! do |virtual_good|
      @point_purchases.get_virtual_good_quantity(virtual_good.key) >= virtual_good.max_purchases
    end
    
    resize_virtual_good_list
  end
  
  ##
  # All virtual goods that have been purchased for this app from this device.
  def purchased
    return unless verify_params([:app_id, :udid])
    
    setup
    
    @virtual_good_list.reject! do |virtual_good|
      @point_purchases.get_virtual_good_quantity(virtual_good.key) == 0
    end
    
    resize_virtual_good_list 
  end
  
  def user_account
    return unless verify_params([:app_id, :udid])
    
    setup
  end
  
  private
  
  def setup
    @point_purchases = PointPurchases.new(:key => "#{params[:udid]}.#{params[:app_id]}")
    @currency = Currency.find_in_cache_by_app_id(params[:app_id])
    if @currency.nil?
      @currency = Currency.new(:app_id => params[:app_id])
      @currency.partner = @currency.app.partner
      @currency.name = ''
      @currency.save!
    end
    mc_key = "virtual_good_list.#{params[:app_id]}"
    @virtual_good_list = get_from_cache_and_save(mc_key, false, 5.minutes) do
      list = []
      VirtualGood.select(:where => "app_id='#{params[:app_id]}' and disabled != '1' and beta != '1'") do |item|
        list.push(item)
      end
      list
    end
    
    if @currency.get_test_device_ids.include?(params[:udid])
      mc_key = "virtual_good_list.beta.#{params[:app_id]}"
      @virtual_good_list = @virtual_good_list | get_from_cache_and_save(mc_key, false, 5.minutes) do
        list = []
        VirtualGood.select(:where => "app_id='#{params[:app_id]}' and disabled != '1' and beta = '1'") do |item|
          list.push(item)
        end
        list
      end
    end
  end
  
  ##
  # Resizes the virtual good list based on the start and max params.
  def resize_virtual_good_list
    start = (params[:start] || 0).to_i
    max = (params[:max] || 999).to_i
    @more_data_available = @virtual_good_list.length - max - start
    @virtual_good_list = @virtual_good_list[start, max] || []    
  end
  
end