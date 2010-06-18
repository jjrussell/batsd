class Job::ConversionTrackingQueueController < Job::SqsReaderController
  include DownloadContent
  include RewardHelper
  include PublisherRecordHelper
  include SqsHelper
  
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
    click = StoreClick.new(:key => "#{udid}.#{advertiser_app_id}")
    
    if not click.get('click_date')
      sleep(5)
      click = StoreClick.new(:key => "#{udid}.#{advertiser_app_id}", :load_from_memcache => false)
      if not click.get('click_date')
        raise "Click not found, wait for failed sdb saves to catch up.  app_id: #{advertiser_app_id}  udid: #{udid}"
      end
    end
    
    if ((not click.get('installed')) && 
        click.get('click_date') > (Time.now.utc - 2.days).to_f.to_s ) #there has been a click but no install
      
      click.put('installed', install_date)
      click.save
      
      reward_key = click.get('reward_key') || UUIDTools::UUID.random_create.to_s
      
      reward = Reward.new(:key => reward_key)
      if reward.get('publisher_app_id') 
        Rails.logger.info 'Reward already in system. Finished processing conversion.'
        return
      end
      
      web_request = WebRequest.new
      web_request.add_path('store_install')
      web_request.put('udid', udid)
      web_request.put('advertiser_app_id', advertiser_app_id)
      web_request.put('publisher_app_id', click.get('publisher_app_id'))
      web_request.save
      
      currency = Currency.find_in_cache_by_app_id(click.get('publisher_app_id'))
      offer = Offer.find_in_cache(advertiser_app_id)
      
      unless click.get('currency_reward')
        click.put('advertiser_amount', currency.get_advertiser_amount(offer))
        click.put('publisher_amount', currency.get_publisher_amount(offer))
        click.put('currency_reward', currency.get_reward_amount(offer))
        click.put('tapjoy_amount', currency.get_tapjoy_amount(offer))
      end
      
      begin
        record_key = lookup_by_record(click.get('publisher_user_record_id'))
        publisher_user_id = record_key.split('.')[1]
      rescue RecordNotFoundException
        message.delete
        raise "Can't find record_id #{click.get('publisher_user_record_id')} on click #{click.key}"
      end
      
      reward.put('type', 'install')
      reward.put('publisher_app_id', click.get('publisher_app_id'))
      reward.put('advertiser_app_id', advertiser_app_id)
      reward.put('publisher_user_id', publisher_user_id, {:cgi_escape => true})
      reward.put('advertiser_amount', click.get('advertiser_amount'))
      reward.put('publisher_amount', click.get('publisher_amount'))
      reward.put('currency_reward', click.get('currency_reward'))
      reward.put('tapjoy_amount', click.get('tapjoy_amount'))
    
      reward.save
    
      message = reward.serialize(:attributes_only => true)
    
      send_to_sqs(QueueNames::SEND_CURRENCY, message) unless currency.callback_url.blank?
      send_to_sqs(QueueNames::SEND_MONEY_TXN, message)
      
      click.put('installed', install_date)
      click.save
    end
  end
end