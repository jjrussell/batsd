class GetOffersController < ApplicationController
  include MemcachedHelper
  include GeoipHelper
  
  def webpage
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
  
    setup
    set_advertiser_app_list(:real_ip => true)
    #store_offer_wall
  end
  
  def featured
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    setup
    set_advertiser_app_list(:real_ip => true)
    
    featured_app_id = 'a67b94ca-7f55-403d-bc67-862a4a020d2a' # Fluent News
   
    @advertiser_app_list.reject! do |app|
      app.key != featured_app_id
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
      params[:udid] = params[:publisher_user_id] if params[:udid] == nil or params[:udid] == ''
    end
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
  
    setup
  
    if params[:type] == '0'
      @offer_list = @publisher_app.get_offer_list(@currency)
      
      if @currency.get('show_rating_offer') == '1'
        rate_app = RateApp.new(:key => "#{@publisher_app.key}.#{params[:udid]}.#{params[:app_version]}")
        unless rate_app.get('rate-date')
          #they haven't rated the app before
          rate_app_offer = CachedOffer.new(:key => '6de89332-0c37-482a-92e6-6fb7a61aec29')
          @offer_list.unshift(rate_app_offer)
        end
      end
      
      render :template => 'get_offers/offers'
    elsif params[:type] == '1'
      use_real_ip = (not(params[:redirect] == '1' or params[:server] == '1'))
      
      set_advertiser_app_list(:real_ip => use_real_ip)
      #store_offer_wall
      
      if params[:redirect] == '1'
        render :template => 'get_offers/installs_redirect'
      elsif params[:server] == '1'
        render :template => 'get_offers/installs_server'
      elsif params[:json] == '1'
        render :template => 'get_offers/installs_json', :content_type => 'application/json'
      else
        render :template => 'get_offers/installs'
      end
    end
  end
  
  private
  
  def setup
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 999).to_i
    
    @publisher_user_record = PublisherUserRecord.new(
        :key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
    @publisher_user_record.update(params[:udid])
    
    @publisher_app = SdbApp.new(:key => params[:app_id])
    @currency = SdbCurrency.new(:key => params[:app_id])
    
    web_request = WebRequest.new
    web_request.put_values('offers', params, request)
    web_request.save
  end
  
  def set_advertiser_app_list(options = {})
    real_ip = options.delete(:real_ip){ true }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    if (not real_ip) and params[:device_ip].nil?
      country = nil
    else
      country = get_geoip_data(params, request).country
    end
    
    geoip_data = get_geoip_data(params, request)
    
    @advertiser_app_list = @publisher_app.get_advertiser_app_list(params[:udid], 
        :currency => @currency, 
        :iphone => (not params[:device_type] =~ /iPod/),
        :ipad => params[:device_type] == 'iPad',
        :country => geoip_data[:country],
        :postal_code => geoip_data[:postal_code],
        :city => geoip_data[:city],
        :start => @start_index,
        :max => @max_items)
    @more_data_available = @advertiser_app_list.length - @max_items - @start_index
    @advertiser_app_list = @advertiser_app_list[@start_index, @max_items] || []
  end
  
  def store_offer_wall
    num_free_apps = 0
    num_apps = @advertiser_app_list.length
    
    offer_wall = OfferWall.new(:load => false)
    
    @advertiser_app_list.each do |advertiser_app|
      num_free_apps += 1 if advertiser_app.is_free
      offer_wall.put('offer_id', advertiser_app.key, :replace => false)
    end
        
    
    offer_wall.put('type', 'rewarded_installs')
    offer_wall.put('udid', params[:udid])
    offer_wall.put('num_free_apps', num_free_apps)
    offer_wall.put('num_apps', num_apps)
    offer_wall.put('publisher_app_id', @publisher_app.key)
    offer_wall.save
  end
  
end