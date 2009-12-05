class GetOffersController < ApplicationController
  include MemcachedHelper
    
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>false</Success>
<ErrorMessage>Wrong Type</ErrorMessage>
</TapjoyConnectReturnObject>
XML_END

    #first lookup the publisher_user_record_id for this user
    record = PublisherUserRecord.new("#{params[:app_id]}.#{params[:publisher_user_id]}")
    unless record.get('record_id') && record.get('int_record_id')
      record.put('record_id',  UUIDTools::UUID.random_create.to_s)
      record.put('int_record_id', record.attributes['record_id'].hash.abs.to_s) #this should work!
      record.save
    end

    xml = "<TapjoyConnectReturnObject>\n"
    if params[:type] == '0'
      xml += get_offerpal_offers
      xml += "<Message>Complete one of the offers below to earn</Message>\n"
    elsif params[:type] == '1'
      xml += get_rewarded_installs(params[:start], params[:max])
      xml += "<Message>Install one of the apps below to earn</Message>\n"
    end
    xml += "</TapjoyConnectReturnObject>"
    
    xml = xml.gsub('INT_IDENTIFIER', record.get('int_record_id')) #no $ because this gets encoded
    xml = xml.gsub('$UDID', params[:udid])
    xml = xml.gsub('$PUBLISHER_USER_RECORD_ID', record.get('record_id'))
    xml = xml.gsub('$APP_ID', params[:app_id])

    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
  
  def get_offerpal_offers
    country = CGI::escape("United States") #for now
    app_id = params[:app_id]
    
    xml = get_from_cache_and_save("offers.s3.#{app_id}.#{country}") do
      xml = AWS::S3::S3Object.value "offers_#{app_id}.#{country}", 'offer-data'
    end
    
    return xml
    
  end
  
  def get_rewarded_installs(start, max)
    app_id = params[:app_id]
    
    device_app = DeviceAppList.new(params[:udid])
    
    xml = get_from_cache_and_save("installs.s3.#{app_id}") do
      xml = AWS::S3::S3Object.value "installs_#{app_id}", 'offer-data'
    end
    
    # remove all apps this user already has
    entire_rewarded_installs = xml.split('^^TAPJOY_SPLITTER^^')
    user_rewarded_installs = []
    
    entire_rewarded_installs.each do |install|
      add = true
      
      device_app.attributes.each do |app|
        if app[0] =~ /^app/ #assuming this is how you get the key from a hash in each
          id = app[0].split('.')[1] 
          add = false if install.include? "<AdvertiserAppID>#{id}</AdvertiserAppID>"
        end
      end
  
      user_rewarded_installs.push install if add
    end
    
    xml = ""
    max.to_i.times do |i|
      xml += user_rewarded_installs[start + i] if start + i < max
    end
    
    xml += "<MoreDataAvailable>#{user_rewarded_installs.length - max - start}</MoreDataAvailable>\n"

    
    return xml
    
  end
  
end