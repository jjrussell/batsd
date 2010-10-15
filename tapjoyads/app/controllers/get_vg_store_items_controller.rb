class GetVgStoreItemsController < ApplicationController

  before_filter :setup
  # TO REMOVE - once the tap defense connect bug has been fixed and is sufficiently adopted
  before_filter :fake_connect_call, :only => :purchased

  ##
  # All virtual goods that are available to be purchased for this app from this device.
  def all
    @virtual_good_list.reject! do |virtual_good|
      @point_purchases.get_virtual_good_quantity(virtual_good.key) >= virtual_good.max_purchases
    end
    
    resize_virtual_good_list
    sort_virtual_good_list
  end
  
  ##
  # All virtual goods that have been purchased for this app from this device.
  def purchased
    @virtual_good_list.reject! do |virtual_good|
      @point_purchases.get_virtual_good_quantity(virtual_good.key) == 0
    end
    
    resize_virtual_good_list
  end
  
  def user_account
  end
  
private
  
  def setup
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    publisher_user_id = params[:udid]
    publisher_user_id = params[:publisher_user_id] unless params[:publisher_user_id].blank?
    
    @currency = Currency.find_in_cache_by_app_id(params[:app_id])
    if @currency.nil?
      @currency = Currency.new(:app_id => params[:app_id])
      @currency.partner = @currency.app.partner
      @currency.name = 'DEFAULT_CURRENCY'
      @currency.callback_url = Currency::TAPJOY_MANAGED_CALLBACK_URL
      @currency.save!
    end
    @point_purchases = PointPurchases.new(:key => "#{publisher_user_id}.#{params[:app_id]}")
    mc_key = "virtual_good_list.#{params[:app_id]}"
    @virtual_good_list = Mc.get_and_put(mc_key, false, 5.minutes) do
      list = []
      VirtualGood.select(:where => "app_id='#{params[:app_id]}' and disabled != '1' and beta != '1'") do |item|
        list.push(item)
      end
      list
    end
    
    if @currency.get_test_device_ids.include?(params[:udid])
      mc_key = "virtual_good_list.beta.#{params[:app_id]}"
      @virtual_good_list = @virtual_good_list | Mc.get_and_put(mc_key, false, 5.minutes) do
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
  
  def sort_virtual_good_list
    @virtual_good_list.sort! do |v1, v2|
      v1.ordinal <=> v2.ordinal
    end
  end
  
  # TO REMOVE - once the tap defense connect bug has been fixed and is sufficiently adopted
  def fake_connect_call
    if params[:app_id] == '2349536b-c810-47d7-836c-2cd47cd3a796' && params[:app_version] == '3.2.2' && params[:library_version] == '5.0.1'
      
      Rails.logger.info_with_time("Check conversions and maybe add to sqs") do
        click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}")
        unless (click.attributes.empty? || click.installed_at)
          logger.info "Added conversion to sqs queue"
          message = { :click => click.serialize(:attributes_only => true), :install_timestamp => Time.zone.now.to_f.to_s }.to_json
          Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
        end
      end
      
      web_request = WebRequest.new
      web_request.put_values('connect', params, get_ip_address, get_geoip_data)
    
      device_app_list = Device.new(:key => params[:udid])
      path_list = device_app_list.set_app_ran(params[:app_id])
      path_list.each do |path|
        web_request.add_path(path)
      end
      
      device_app_list.save
      web_request.save
    end
  end
  
end