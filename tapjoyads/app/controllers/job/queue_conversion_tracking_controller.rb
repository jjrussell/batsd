class Job::QueueConversionTrackingController < Job::SqsReaderController
  
  def initialize
    super QueueNames::CONVERSION_TRACKING
  end
  
private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    click = Click.deserialize(json['click'])
    installed_at_epoch = json['install_timestamp']
    
    if click.installed_at? || click.clicked_at < (Time.zone.now - 2.days) || click.block_reason?
      return
    end
    
    currency = Currency.find_in_cache(click.currency_id, true)
    
    # Try to stop Playdom users from click-frauding (specifically from Mobsters: Big Apple)
    if currency.callback_url == Currency::PLAYDOM_CALLBACK_URL && click.publisher_user_id !~ /^(F|M|P)[0-9]+$/
      click.block_reason = "InvalidPlaydomUserId"
      click.serial_save
      Notifier.alert_new_relic(InvalidPlaydomUserId, "Playdom User id: '#{click.publisher_user_id}' is invalid, for click: #{click.key}", request, params)
      return
    end
    
    publisher_user_record = PublisherUserRecord.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
    unless publisher_user_record.update(click.udid)
      click.block_reason = "TooManyUdidsForPublisherUserId (ID=#{publisher_user_record.key})"
      click.serial_save
      Notifier.alert_new_relic(TooManyUdidsForPublisherUserId, "Too many UDIDs associated with publisher_user_record: #{publisher_user_record.key}, for click: #{click.key}", request, params)
      return
    end
    
    # Do not reward if user has installed this app for the same publisher user id on another device
    offer = Offer.find_in_cache(click.offer_id, true)
    unless offer.multi_complete?
      other_udids = publisher_user_record.get('udid', :force_array => true) - [ click.udid ]
      other_udids.each do |udid|
        device = Device.new(:key => udid)
        if device.has_app(click.advertiser_app_id)
          click.block_reason = "AlreadyRewardedForPublisherUserId (UDID=#{udid})"
          click.serial_save
          Notifier.alert_new_relic(AlreadyRewardedForPublisherUserId, "Offer already rewarded for publisher_user_record: #{publisher_user_record.key}, for click: #{click.key}", request, params)
          return
        end
      end
    end
    
    unless click.reward_key
      raise "Click #{click.key} missing reward key!"
    end
    
    device = Device.new(:key => click.udid)
    if device.is_jailbroken && offer.is_paid? && offer.item_type == 'App' && click.type == 'install'
      click.tapjoy_amount += click.advertiser_amount
      click.advertiser_amount = 0
      click.type += '_jailbroken'
      Notifier.alert_new_relic(JailbrokenInstall, "Device: #{click.udid} is jailbroken and installed a paid app: #{click.advertiser_app_id}, for click: #{click.key}", request, params)
    end
    
    click.type = "featured_#{click.type}" if click.source == 'featured'
    
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
    
    message = reward.serialize(:attributes_only => true)
    
    Sqs.send_message(QueueNames::SEND_CURRENCY, message) unless currency.callback_url == Currency::NO_CALLBACK_URL
    Sqs.send_message(QueueNames::CREATE_CONVERSIONS, message)
  end
end
