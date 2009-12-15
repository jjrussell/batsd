class Job::ConversionTrackingQueueController < Job::SqsReaderController
  include DownloadContent
  include RewardHelper
  
  def initialize
    super QueueNames::CONVERSION_TRACKING
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    udid = json['udid']
    advertiser_app_id = json['app_id']
    install_date = json['install_date']
    
    Rails.logger.info "Checking for conversion on #{udid} for #{advertiser_app_id}"
    click = StoreClick.new("#{udid}.#{advertiser_app_id}")

    if (click.get('click_date') && (not click.get('installed')) ) #there has been a click but no install
      
      if click.get('publisher_app_id') == '93e78102-cbd7-4ebf-85cc-315ba83ef2d5' #EasyApp
        #for now, make easyapp numbers go to the new system
        adv_app = App.new(advertiser_app_id)
        
        publisher_app_id = click.get('publisher_app_id')
        currency = Currency.new(publisher_app_id)
        
        values = calculate_install_payouts(:currency => currency, :advertiser_app => adv_app)
        
        publisher_user_record_id = click.get('publisher_user_record_id')
        publisher_user_id = publisher_user_record_id.split('.')[1]
        
        reward = Reward.new
        reward.put('type', 'install')
        reward.put('publisher_app_id', publisher_app_id)
        reward.put('advertiser_app_id', advertiser_app_id)
        reward.put('publisher_user_id', publisher_user_id)
        reward.put('advertiser_amount', click.get('advertiser_amount'))
        reward.put('publisher_amount', click.get('publisher_amount'))
        reward.put('currency_reward', click.get('currency_reward'))
        reward.put('tapjoy_amount', click.get('tapjoy_amount'))
        reward.put('offerpal_amount', click.get('offerpal_amount'))
        
        reward.save
        
        message = reward.serialize()
        
        SqsGen2.new.queue(QueueNames::SEND_CURRENCY).send_message(message)
        SqsGen2.new.queue(QueueNames::SEND_MONEY_TXN).send_message(message)

        
      else
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
        
        download_content(url, {:timeout => 15})
      
        click.put('installed', "#{install_date.to_s}")
        click.save
      end
    end
  end
end