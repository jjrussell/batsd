class ConversionTrackingProcessor < ApplicationProcessor
  include DownloadContent
  
  subscribes_to :conversion_tracking
  
  def on_message(message)
    
    json = JSON.parse(message)
    udid = json['udid']
    advertiser_app_id = json['app_id']
    install_date = json['install_date']
    
    Rails.logger.info "Checking for conversion on #{udid} for #{advertiser_app_id}"
    click = StoreClick.new("#{udid}.#{advertiser_app_id}")

    if (click.get('click_date') && (not click.get('installed')) ) #there has been a click but no install
      
      publisher_app_id = click.get('publisher_app_id')
      publisher_user_record_id = click.get('publisher_user_record_id')
      click_date = click.get('click_date').to_f
      
      Rails.logger.info "Processing conversion for #{udid} on #{advertiser_app_id} is for " +
        "#{publisher_app_id} with record #{publisher_user_record_id}"            
      
      win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/Service1.asmx/'
      url = win_lb + "SubmitRewardedInstallConversion?password=asfyrexvlkjewr214314" + 
        "&PublisherAppId=#{publisher_app_id}&AdvertiserAppId=#{advertiser_app_id}" +
        "&ClickDate=#{click_date.to_i}&InstallDate=#{install_date.to_i}" +
        "&DeviceTag=#{udid}&PublisherUserID=#{publisher_user_record_id}" +
        "&MoneyPaidForInstall=0"
        
      Rails.logger.info "Calling #{url}"
      
      download_content(url, {}, 15) #15 second timeout
      
      click.put('installed',"#{install_date.to_s}")
      click.save

      
    end #worth checking conversions

  end
  
end