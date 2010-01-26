class GetOffersController < ApplicationController
  include MemcachedHelper
  
  def webpage
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
  
    rewarded_installs
  end
    
  def index
    return unless verify_params([:app_id, :udid], {:allow_empty => false})
    
    #special code for Tapulous not sending udid
    if params[:app_id] == 'e2479a17-ce5e-45b3-95be-6f24d2c85c6f'
      params[:udid] = params[:publisher_user_id] if params[:udid] == nil or params[:udid] == ''
    end
  
    #first lookup the publisher_user_record_id for this user
    record = PublisherUserRecord.new(:key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
    record.update(params[:udid])
    
    currency = Currency.new(:key => params[:app_id])

    xml = "<TapjoyConnectReturnObject>\n"
    if params[:type] == '0'
      xml += get_offerpal_offers(params[:app_id], params[:udid], currency, params[:app_version])
      xml += "<Message>Complete one of the offers below to earn #{CGI::escapeHTML(currency.get('currency_name'))}</Message>\n"
    elsif params[:type] == '1'
      rewarded_installs
      
      if params[:redirect] == '1'
        render :template => 'get_offers/installs_redirect'
      elsif params[:server] == '1'
        render :template => 'get_offers/installs_server'
      else
        render :template => 'get_offers/installs'
      end
      return
    end
    xml += "</TapjoyConnectReturnObject>"
    
    xml = xml.gsub('INT_IDENTIFIER', record.get('int_record_id', :force_array => true)[0]) #no $ because this gets encoded
    xml = xml.gsub('$UDID', params[:udid])
    xml = xml.gsub('$PUBLISHER_USER_RECORD_ID', record.get('record_id', :force_array => true)[0])
    xml = xml.gsub('$APP_ID', params[:app_id])

    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
  
  private
  
  def get_offerpal_offers(app_id, udid, currency, version)
    country = CGI::escape("United States") #for now
    
    xml = get_from_cache_and_save("offers.s3.#{app_id}.#{country}") do
      xml = AWS::S3::S3Object.value "offers_#{app_id}.#{country}", RUN_MODE_PREFIX + 'offer-data'
    end
    
    if currency.get('show_rating_offer') == '1'
      rate = RateApp.new(:key => "#{app_id}.#{udid}.#{version}")
      unless rate.get('rate-date')
        #they haven't rated the app before
        offer = create_rating_offer(app_id, udid, currency, version)
        first_line = "<OfferArray>\n"
        old_xml = xml[first_line.length,xml.length]
        xml = first_line + offer + old_xml
      end
    end
    
    return xml
    
  end
  
  def create_rating_offer(app_id, udid, currency, version)
    #thank god for memcached, but this should be optimized
    
    app = App.new(:key => app_id)
    offer = ReturnOffer.new(3, app.get('name'), currency)
    offer.ActionURL = "http://ws.tapjoyads.com/rate_app_offer?record_id=$PUBLISHER_USER_RECORD_ID&udid=#{udid}&app_id=#{app_id}&app_version=#{version}"
    
    return offer.to_xml
  end
  
  def rewarded_installs
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 30).to_i
    
    #first lookup the publisher_user_record_id for this user
    @publisher_user_record = PublisherUserRecord.new(
        :key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
    @publisher_user_record.update(params[:udid])
    
    @currency = Currency.new(:key => params[:app_id])
    @publisher_app = App.new(:key => params[:app_id])
    @advertiser_app_list = @publisher_app.get_advertiser_app_list(params[:udid], 
        :currency => @currency, :iphone => (not params[:device_type] =~ /iPod/))
    
    num_free_apps = 0
    num_apps = @advertiser_app_list.length
    @advertiser_app_list.each do |advertiser_app|
      num_free_apps += 1 if advertiser_app.is_free
    end
        
    offer_wall = OfferWall.new
    offer_wall.put('type', 'rewarded_installs')
    offer_wall.put('udid', params[:udid])
    offer_wall.put('num_free_apps', num_free_apps)
    offer_wall.put('num_apps', num_apps)
    offer_wall.put('publisher_app_id', @publisher_app.key)
    offer_wall.save
  end
  
end