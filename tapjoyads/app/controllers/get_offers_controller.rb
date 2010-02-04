class GetOffersController < ApplicationController
  include MemcachedHelper
  
  def webpage
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
  
    setup
    rewarded_installs
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
      rewarded_installs
      
      if params[:redirect] == '1'
        render :template => 'get_offers/installs_redirect'
      elsif params[:server] == '1'
        render :template => 'get_offers/installs_server'
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
    
    @publisher_app = App.new(:key => params[:app_id])
    @currency = Currency.new(:key => params[:app_id])
    
    web_request = WebRequest.new
    web_request.put_values('offers', params, request)
    web_request.save
  end
  
  def rewarded_installs
    @advertiser_app_list = @publisher_app.get_advertiser_app_list(params[:udid], 
        :currency => @currency, :iphone => (not params[:device_type] =~ /iPod/))
    
    num_free_apps = 0
    num_apps = @advertiser_app_list.length
    @advertiser_app_list.each do |advertiser_app|
      num_free_apps += 1 if advertiser_app.is_free
    end
        
    offer_wall = OfferWall.new(:load => false)
    offer_wall.put('type', 'rewarded_installs')
    offer_wall.put('udid', params[:udid])
    offer_wall.put('num_free_apps', num_free_apps)
    offer_wall.put('num_apps', num_apps)
    offer_wall.put('publisher_app_id', @publisher_app.key)
    offer_wall.save
  end
  
end