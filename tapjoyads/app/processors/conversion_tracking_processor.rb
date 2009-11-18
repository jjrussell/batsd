class ConversionTrackingProcessor < ApplicationProcessor
  include DownloadContent
  
  subscribes_to :conversion_tracking
  
  def on_message(message)
    
    json = JSON.parse(message)
    udid = json['udid']
    advertiser_app_id = json['app_id']
    
    now = Time.now.utc
    Rails.logger.info 'Checking for conversion'
    click = StoreClick.new("#{udid}.#{advertiser_app_id}")

    if (click.get('last_click') && (not click.get('installed')) ) #there has been a click but no install
      Rails.logger.info "Processing conversion for #{udid} on #{advertiser_app_id}"
      
      #we need to find the best one
      best_date = 0
      best_app = ''
      publisher_record = ''
      money = ''
      
      click.item.attributes.each do |a| 
        attribute_parts = a.to_a
        key = attribute_parts[0]
        value = attribute_parts[1]
        if key =~ /^publisher/ #finding all attributes that start with publisher.
          value_parts = value.split('@') #use @ because the date contains a .
          if value_parts.length == 3
          
            click_date = value_parts[0].to_f #epoch
          
            if (click_date > best_date)
              best_date = click_date
            
              key_parts = key.split('.')
              next if key_parts.length != 2
              best_app = key_parts[1]
              publisher_record = value_parts[1]
              money = value_parts[2]
              
            end #the best date
          end
        end #attributes that start with publisher               
      end #each attribute
      
      Rails.logger.info "Best conversion for #{udid} on #{advertiser_app_id} is for " +
        "#{best_app} with record #{publisher_record}"            
      
      win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/Service1.asmx/'
      url = win_lb + "SubmitRewardedInstallConversion?password=asfyrexvlkjewr214314" + 
        "&PublisherAppId=#{best_app}&AdvertiserAppId=#{advertiser_app_id}" +
        "&ClickDate=#{best_date.to_i}&InstallDate=#{now.to_i.to_s}" +
        "&DeviceTag=#{udid}&PublisherUserID=#{publisher_record}" +
        "&MoneyPaidForInstall=#{money}"
        
      Rails.logger.info "Calling #{url}"
      
      download_content(url, {}, 15000) #15 second timeout
      
      click.put('installed',"#{best_app}")
      click.save
      
    end #worth checking conversions

  end
  
end