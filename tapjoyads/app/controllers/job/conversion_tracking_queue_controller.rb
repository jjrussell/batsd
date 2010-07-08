class Job::ConversionTrackingQueueController < Job::SqsReaderController
  include DownloadContent
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
    
    unless click.clicked_at
      sleep(5)
      click = StoreClick.new(:key => "#{udid}.#{advertiser_app_id}", :load_from_memcache => false)
      unless click.clicked_at
        raise "Click not found, wait for failed sdb saves to catch up.  app_id: #{advertiser_app_id}  udid: #{udid}"
      end
    end
    
    if click.installed_at || click.clicked_at < (Time.zone.now - 2.days)
      return
    end
    
    publisher_user_record = PublisherUserRecord.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
    unless publisher_user_record.update(udid)
      message.delete
      raise "Too many UDIDs associated with publisher_user_record: #{publisher_user_record.key}"
    end
    
    click.put('installed', install_date)
    click.save
    
    reward_key = click.reward_key || UUIDTools::UUID.random_create.to_s
    
    reward = Reward.new(:key => reward_key)
    if reward.get('publisher_app_id') 
      Rails.logger.info 'Reward already in system. Finished processing conversion.'
      return
    end
    
    web_request = WebRequest.new
    web_request.add_path('store_install')
    web_request.put('udid', udid)
    web_request.put('advertiser_app_id', advertiser_app_id)
    web_request.put('publisher_app_id', click.publisher_app_id)
    web_request.save
    
    currency = Currency.find_in_cache_by_app_id(click.publisher_app_id)
    offer = Offer.find_in_cache(advertiser_app_id)
    
    reward.put('type', 'install')
    reward.put('publisher_app_id', click.publisher_app_id)
    reward.put('advertiser_app_id', advertiser_app_id)
    reward.put('publisher_user_id', click.publisher_user_id)
    reward.put('advertiser_amount', click.advertiser_amount)
    reward.put('publisher_amount', click.publisher_amount)
    reward.put('currency_reward', click.currency_reward)
    reward.put('tapjoy_amount', click.tapjoy_amount)
    reward.put('source', click.source)
    reward.put('udid', udid)
    
    reward.save
    
    message = reward.serialize(:attributes_only => true)
    
    send_to_sqs(QueueNames::SEND_CURRENCY, message) unless currency.callback_url.blank?
    send_to_sqs(QueueNames::SEND_MONEY_TXN, message)
    
    click.put('installed', install_date)
    click.save
  end
end