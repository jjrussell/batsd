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
  
  def get_rewarded_installs(start, max, udid, type, currency, set_app_list = false, record_id = nil)
    app_id = params[:app_id]
    
    device_app_list = DeviceAppList.new(:key => params[:udid])
    
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
      
      if udid != '298c5159a3681207eaba5a04b3573aa7b4f13d99' # Ben's udid. Show all apps on his device.
        device_app_list.get_app_list.each do |app_id|
          add = false if install.include? "<AdvertiserAppID>#{app_id}</AdvertiserAppID>" 
          add = false if install.include? "advertiser_app_id=#{app_id}"
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
        if set_app_list
          app = {}
          begin
            app['url'] = CGI::unescapeHTML(xml_fragment.match(/<RedirectURL>(.*)<\/RedirectURL>/)[1].gsub('$PUBLISHER_USER_RECORD_ID',record_id).gsub('$UDID',udid))
            app['icon_url'] = xml_fragment.match(/<IconURL>(.*)<\/IconURL>/)[1]
            app['name'] = xml_fragment.match(/<Name>(.*)<\/Name>/)[1]
            app['amount'] = xml_fragment.match(/<Amount>(.*)<\/Amount>/)[1]
            app['cost'] = xml_fragment.match(/<Cost>(.*)<\/Cost>/)[1]
            @app_list.push(app)
          rescue Exception => e
            Rails.logger.info "Exception adding #{e}"
          end
        end
      end
    end
    
    xml += "</OfferArray>\n"
    xml += "<MoreDataAvailable>#{user_rewarded_installs.length - max - start}</MoreDataAvailable>\n" if user_rewarded_installs.length - max - start > 0

    offer_wall = OfferWall.new
    offer_wall.put('type', 'rewarded_installs')
    offer_wall.put('udid', udid)
    offer_wall.put('num_free_apps', num_free_apps)
    offer_wall.put('num_apps', num_apps)
    offer_wall.put('publisher_app_id', app_id)
    offer_wall.save
    
    # TODO: Add OfferWall's id to the xml's ActionURL. Also change ConnectController to handle
    # the presence of an uuid before the url, and track conversions.
    
    return xml
  end
  
  def rewarded_installs
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