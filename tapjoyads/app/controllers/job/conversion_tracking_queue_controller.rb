class Job::ConversionTrackingQueueController < Job::SqsReaderController
  
  def initialize
    super QueueNames::CONVERSION_TRACKING
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    udid = json['udid']
    advertiser_app_id = json['app_id']
    installed_at_epoch = json['install_date']
    
    Rails.logger.info "Checking for conversion on #{udid} for #{advertiser_app_id}"
    click = Click.new(:key => "#{udid}.#{advertiser_app_id}")
    
    unless click.clicked_at
      sleep(5)
      click = Click.new(:key => "#{udid}.#{advertiser_app_id}", :load_from_memcache => false)
      unless click.clicked_at
        raise "Click not found, wait for failed sdb saves to catch up.  app_id: #{advertiser_app_id}  udid: #{udid}"
      end
    end
    
    if click.installed_at || click.clicked_at < (Time.zone.now - 2.days)
      return
    end
    
    currency = Currency.find_in_cache_by_app_id(click.publisher_app_id)
    
    # Try to stop Playdom users from click-frauding (specifically from Mobsters: Big Apple)
    if currency.callback_url == 'PLAYDOM_DEFINED' && click.publisher_user_id !~ /^(F|M|P)[0-9]+$/
      Notifier.alert_new_relic(InvalidPlaydomUserId, "Playdom User id: '#{click.publisher_user_id}' is invalid")
      return
    end
    
    publisher_user_record = PublisherUserRecord.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
    unless publisher_user_record.update(udid)
      Notifier.alert_new_relic(TooManyUdidsForPublisherUserId, "Too many UDIDs associated with publisher_user_record: #{publisher_user_record.key}, for click: #{click.key}")
      return
    end
    
    unless click.reward_key
      raise "Click #{click.key} missing reward key!"
    end
    
    reward = Reward.new(:key => click.reward_key)
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
    reward.put('country', click.country)
    
    begin
      reward.serial_save(:catch_exceptions => false, :expected_attr => { 'type' => nil })
    rescue ExpectedAttributeError => e
      Notifier.alert_new_relic(DuplicateConversionBlocked, "Reward: #{reward.key}.")
      return
    end
    
    click.put('installed_at', installed_at_epoch)
    click.save
    
    web_request = WebRequest.new
    web_request.add_path('store_install')
    web_request.put('udid', udid)
    web_request.put('advertiser_app_id', advertiser_app_id)
    web_request.put('publisher_app_id', click.publisher_app_id)
    web_request.put('offer_id', click.offer_id)
    web_request.put('publisher_user_id', click.publisher_user_id)
    web_request.put('source', click.source)
    web_request.save
    
    message = reward.serialize(:attributes_only => true)
    
    Sqs.send_message(QueueNames::SEND_CURRENCY, message) unless currency.callback_url.blank?
    Sqs.send_message(QueueNames::SEND_MONEY_TXN, message)
  end
end
