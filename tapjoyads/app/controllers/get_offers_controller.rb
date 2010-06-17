class GetOffersController < ApplicationController
  include MemcachedHelper
  include GeoipHelper
  
  def webpage
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
  
    setup
    set_offer_list(:require_device_ip_param => false)
  end
  
  def featured
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    setup
    set_offer_list(:require_device_ip_param => false)
    
    featured_app_id = 'a67b94ca-7f55-403d-bc67-862a4a020d2a' # Fluent News
   
    @offer_list.reject! do |offer|
      offer.id != featured_app_id
    end
    @more_data_available = 0
    
    if params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs_redirect'
    end
  end
  
  def index
    #special code for Tapulous not sending udid
    if params[:app_id] == 'e2479a17-ce5e-45b3-95be-6f24d2c85c6f'
      params[:udid] = params[:publisher_user_id] if params[:udid].blank?
    end
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
  
    setup
    
    require_device_ip_param = (params[:redirect] == '1' || params[:server] == '1')
    
    set_offer_list(:require_device_ip_param => require_device_ip_param)
    
    if params[:type] == '0'
      render :template => 'get_offers/offers'
    elsif params[:redirect] == '1'
      render :template => 'get_offers/installs_redirect'
    elsif params[:server] == '1'
      render :template => 'get_offers/installs_server'
    elsif params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs'
    end
  end
  
  private
  
  def setup
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 999).to_i
    
    @publisher_user_record = PublisherUserRecord.new(
        :key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
    @publisher_user_record.update(params[:udid])
    
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache(params[:app_id])
    
    web_request = WebRequest.new
    web_request.put_values('offers', params, request)
    web_request.save
  end
  
  def set_offer_list(options = {})
    require_device_ip_param = options.delete(:require_device_ip_param){ false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    if require_device_ip_param && params[:device_ip].blank?
      geoip_data = {}
    else
      geoip_data = get_geoip_data(params, request)
    end
    
    type = params[:type] == '0' ? '0' : '1'
    
    @offer_list, @more_data_available = @publisher_app.get_offer_list(params[:udid], 
        :currency => @currency,
        :device_type => params[:device_type],
        :geoip_data => geoip_data,
        :type => type,
        :required_length => (@start_index + @max_items))
    @offer_list = @offer_list[@start_index, @max_items] || []
  end
end
