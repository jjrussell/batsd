class GetOffersController < ApplicationController
  include MemcachedHelper
  
  layout 'iphone', :only => :webpage
  
  def webpage
    setup
    
    set_offer_list(:require_device_ip_param => false)
  end
  
  def featured
    params[:type] = Offer::FEATURED_OFFER_TYPE
    params[:start] = '0'
    params[:max] = '999'
    
    setup
    
    set_offer_list(:require_device_ip_param => false)
    
    @offer_list = @offer_list[rand(@offer_list.length).to_i, 1]
    @more_data_available = 0
    @source = 'featured'
    
    if params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs_redirect'
    end
  end
  
  def index
    setup
    
    require_device_ip_param = (params[:redirect] == '1' || params[:server] == '1')
    
    set_offer_list(:require_device_ip_param => require_device_ip_param)
    
    if params[:type] == Offer::CLASSIC_OFFER_TYPE
      render :template => 'get_offers/offers'
    elsif params[:redirect] == '1'
      render :template => 'get_offers/installs_redirect'
    elsif params[:server] == '1'
      @source = 'server'
      render :template => 'get_offers/installs_server'
    elsif params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs'
    end
  end
  
private
  
  def setup
    # special code for Tapulous not sending udid
    if params[:app_id] == 'e2479a17-ce5e-45b3-95be-6f24d2c85c6f'
      params[:udid] = params[:publisher_user_id] if params[:udid].blank?
    end
    return unless verify_params([ :app_id, :udid, :publisher_user_id ], { :allow_empty => false })
    
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 25).to_i
    @source = ''
    
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache_by_app_id(params[:app_id])
    
    web_request = WebRequest.new
    web_request.put_values('offers', params, get_ip_address, get_geoip_data)
    web_request.save
  end
  
  def set_offer_list(options = {})
    require_device_ip_param = options.delete(:require_device_ip_param) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    if require_device_ip_param && params[:device_ip].blank?
      geoip_data = {}
    else
      geoip_data = get_geoip_data
    end
    
    type = case params[:type]
    when Offer::FEATURED_OFFER_TYPE
      Offer::FEATURED_OFFER_TYPE
    when Offer::CLASSIC_OFFER_TYPE
      Offer::CLASSIC_OFFER_TYPE
    else
      Offer::DEFAULT_OFFER_TYPE
    end
    
    @offer_list, @more_data_available = @publisher_app.get_offer_list(params[:udid], 
        :currency => @currency,
        :device_type => params[:device_type],
        :geoip_data => geoip_data,
        :type => type,
        :required_length => (@start_index + @max_items),
        :app_version => params[:app_version])
    @offer_list = @offer_list[@start_index, @max_items] || []
  end
end
