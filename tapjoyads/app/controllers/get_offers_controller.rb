class GetOffersController < ApplicationController
  include MemcachedHelper
    
  missing_message = "missing required params"
  verify :params => [:udid, :app_id],
         :only => :index,
         :render => {:text => missing_message}
    
  def index
    #special code for Tapulous not sending udid
    if params[:app_id] == 'e2479a17-ce5e-45b3-95be-6f24d2c85c6f'
      params[:udid] = params[:publisher_user_id] if params[:udid] == nil or params[:udid] == ''
    end
  
    #first lookup the publisher_user_record_id for this user
    record = PublisherUserRecord.new("#{params[:app_id]}.#{params[:publisher_user_id]}")
    unless record.get('record_id') && record.get('int_record_id') && record.get('udid')
      uid = UUIDTools::UUID.random_create.to_s
      record.put('record_id',  uid)
      record.put('int_record_id', uid.hash.abs.to_s) #this should work!
      record.put('udid', params[:udid])
      record.save({:replace => false})
      save_to_cache("record_id.#{record.get('record_id')}", record.key)
      save_to_cache("int_record_id.#{record.get('int_record_id')}", record.key)
    end
    
    currency = Currency.new(params[:app_id])

    xml = "<TapjoyConnectReturnObject>\n"
    if params[:type] == '0'
      xml += get_offerpal_offers(params[:app_id], params[:udid], currency, params[:app_version])
      xml += "<Message>Complete one of the offers below to earn #{CGI::escapeHTML(currency.get('currency_name'))}</Message>\n"
    elsif params[:type] == '1'
      type = ''
      type = 'server.' if params[:server] == '1'
      type = 'redirect.' if params[:redirect] == '1'
      Rails.logger.info "type = #{type}"
      xml += get_rewarded_installs(params[:start].to_i, params[:max].to_i, params[:udid], type, currency)
      xml += "<Message>Install one of the apps below to earn #{CGI::escapeHTML(currency.get('currency_name'))}</Message>\n"
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
      rate = RateApp.new("#{app_id}.#{udid}.#{version}")
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
    
    app = App.new(app_id)
    offer = ReturnOffer.new(3, app.get('name'), currency)
    offer.ActionURL = "http://ws.tapjoyads.com/rate_app_offer?record_id=$PUBLISHER_USER_RECORD_ID&udid=#{udid}&app_id=#{app_id}&app_version=#{version}"
    
    return offer.to_xml
  end
  
  def get_rewarded_installs(start, max, udid, type, currency)
    app_id = params[:app_id]
    
    device_app = DeviceAppList.new(params[:udid])
    
    xml = get_from_cache_and_save("#{type}installs.s3.#{app_id}") do
      xml =  AWS::S3::S3Object.value "#{type}installs_#{app_id}", RUN_MODE_PREFIX + 'offer-data'
    end
    
    # remove all apps this user already has
    entire_rewarded_installs = xml.split('^^TAPJOY_SPLITTER^^')
    user_rewarded_installs = []
    
    only_free_apps = false
    only_free_apps = true if currency.get('only_free_apps') == '1'
    
    entire_rewarded_installs.each do |install|
      add = true
      
      device_app.attributes.each do |app|
        if app[0] =~ /^app/ #assuming this is how you get the key from a hash in each
          id = app[0].split('.')[1] 
          if udid != '298c5159a3681207eaba5a04b3573aa7b4f13d99'
            add = false if install.include? "<AdvertiserAppID>#{id}</AdvertiserAppID>" 
            add = false if install.include? "advertiser_app_id=#{id}"
          end
        end
      end
      
      add = false if only_free_apps && install.match('<Cost>Paid</Cost>') != nil
      
      if install =~ /TAPJOY_IPHONE_ONLY/ 
        add = false if params[:device_type] =~ /iPod/
        install = install.gsub(/TAPJOY_IPHONE_ONLY/,'')
      end
        
      user_rewarded_installs.push install if add
    end
    
    xml = "<OfferArray>\n"
    
    num_free_apps = 0
    num_apps = 0
    advertiser_app_ids = []
    
    max.times do |i|
      if start + i < user_rewarded_installs.length
        xml_fragment = user_rewarded_installs[start + i]
        xml += xml_fragment
       
        num_apps += 1
        if xml_fragment =~ /<Cost>Free<\/Cost>/
          num_free_apps += 1
        end
        advertiser_app_id = xml_fragment.match(/<AdvertiserAppID>(.*)<\/AdvertiserAppID>/)[1]
        advertiser_app_ids.push(advertiser_app_id)
      end
    end
    
    xml += "</OfferArray>\n"
    xml += "<MoreDataAvailable>#{user_rewarded_installs.length - max - start}</MoreDataAvailable>\n" if user_rewarded_installs.length - max - start > 0

    offer_wall = OfferWall.new
    offer_wall.put('type', 'rewarded_installs')
    offer_wall.put('udid', udid)
    offer_wall.put('num_free_apps', num_free_apps)
    offer_wall.put('num_apps', num_apps)
    offer_wall.put('advertiser_app_ids', advertiser_app_ids.join(','))
    offer_wall.put('publisher_app_id', app_id)
    offer_wall.save
    
    # TODO: Add OfferWall's id to the xml's ActionURL. Also change ConnectController to handle
    # the presence of an uuid before the url, and track conversions.
    
    return xml
  end
  
end