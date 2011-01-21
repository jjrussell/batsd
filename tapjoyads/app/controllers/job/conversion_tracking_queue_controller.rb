class Job::ConversionTrackingQueueController < Job::SqsReaderController
  
  def initialize
    super QueueNames::CONVERSION_TRACKING
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    click = Click.deserialize(json['click'])
    installed_at_epoch = json['install_timestamp']
    
    if click.installed_at || click.clicked_at < (Time.zone.now - 2.days)
      return
    end
    
    currency = Currency.find_in_cache(click.currency_id, true)
    
    # Try to stop Playdom users from click-frauding (specifically from Mobsters: Big Apple)
    if currency.callback_url == Currency::PLAYDOM_CALLBACK_URL && click.publisher_user_id !~ /^(F|M|P)[0-9]+$/
      Notifier.alert_new_relic(InvalidPlaydomUserId, "Playdom User id: '#{click.publisher_user_id}' is invalid", request, params)
      return
    end
    
    publisher_user_record = PublisherUserRecord.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
    unless publisher_user_record.update(click.udid)
      Notifier.alert_new_relic(TooManyUdidsForPublisherUserId, "Too many UDIDs associated with publisher_user_record: #{publisher_user_record.key}, for click: #{click.key}", request, params)
      return
    end
    
    unless click.reward_key
      raise "Click #{click.key} missing reward key!"
    end
    
    wr_path = 'conversion'
    offer = Offer.find_in_cache(click.offer_id, true)
    device = Device.new(:key => click.udid)
    if device.is_jailbroken && offer.is_paid? && offer.item_type == 'App' && click.type == 'install'
      click.tapjoy_amount += click.advertiser_amount
      click.advertiser_amount = 0
      click.type = 'install_jailbroken'
      wr_path += '_jailbroken'
      Notifier.alert_new_relic(JailbrokenInstall, "Device: #{click.udid} is jailbroken and installed a paid app: #{click.advertiser_app_id}", request, params)
    end
    
    reward = Reward.new(:key => click.reward_key)
    reward.put('created', installed_at_epoch)
    reward.type              = click.type
    reward.publisher_app_id  = click.publisher_app_id
    reward.advertiser_app_id = click.advertiser_app_id
    reward.displayer_app_id  = click.displayer_app_id
    reward.offer_id          = click.offer_id
    reward.currency_id       = click.currency_id
    reward.publisher_user_id = click.publisher_user_id
    reward.advertiser_amount = click.advertiser_amount
    reward.publisher_amount  = click.publisher_amount
    reward.displayer_amount  = click.displayer_amount
    reward.currency_reward   = click.currency_reward
    reward.tapjoy_amount     = click.tapjoy_amount
    reward.source            = click.source
    reward.udid              = click.udid
    reward.country           = click.country
    reward.reward_key_2      = click.reward_key_2
    reward.exp               = click.exp
    reward.viewed_at         = click.viewed_at
    
    begin
      reward.serial_save(:catch_exceptions => false, :expected_attr => { 'type' => nil })
    rescue Simpledb::ExpectedAttributeError => e
      return
    end
    
    click.put('installed_at', installed_at_epoch)
    click.serial_save
    
    web_request = WebRequest.new
    web_request.add_path(wr_path)
    web_request.put('time', installed_at_epoch)
    web_request.udid              = click.udid
    web_request.advertiser_app_id = click.advertiser_app_id
    web_request.publisher_app_id  = click.publisher_app_id
    web_request.displayer_app_id  = click.displayer_app_id
    web_request.offer_id          = click.offer_id
    web_request.currency_id       = currency.id
    web_request.publisher_user_id = click.publisher_user_id
    web_request.source            = click.source
    web_request.exp               = click.exp
    web_request.viewed_at         = click.viewed_at
    web_request.serial_save
    
    message = reward.serialize(:attributes_only => true)
    
    Sqs.send_message(QueueNames::SEND_CURRENCY, message) unless currency.callback_url == Currency::NO_CALLBACK_URL
    Sqs.send_message(QueueNames::SEND_MONEY_TXN, message)
  end
end
