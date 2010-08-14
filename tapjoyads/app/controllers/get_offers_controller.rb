class GetOffersController < ApplicationController
  
  layout 'iphone', :only => :webpage
  
  before_filter :set_featured_params, :only => :featured
  before_filter :setup
  
  def webpage
    set_offer_list(:require_device_ip_param => false)
    
    @message = nil
    unless params[:featured_offer].blank?
      featured_offer = Offer.find_in_cache(params[:featured_offer])
      
      if featured_offer.featured? && @offer_list.include?(featured_offer)
        redirect_to featured_offer.get_redirect_url(@publisher_app, params[:publisher_user_id], params[:udid], 'featured', params[:app_version])
        return
      end
      @message = "You have already installed #{featured_offer.name}. You can still complete " +
          "one of the offers below to earn #{@currency.name}."
    end
  end
  
  def featured
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
    
    if params[:type] == Offer::CLASSIC_OFFER_TYPE
       publisher_user_record = PublisherUserRecord.new(:key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
       publisher_user_record.update(params[:udid])
    end
    
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
        :app_version => params[:app_version],
        :reject_rating_offer => params[:rate_app_offer] == '0',
        :sdk_version => params[:library_version].to_f)
    @offer_list = @offer_list[@start_index, @max_items] || []
  end
  
  def set_featured_params
    params[:type] = Offer::FEATURED_OFFER_TYPE
    params[:start] = '0'
    params[:max] = '999'
  end
  
end
