class Job::QueueConversionTrackingController < Job::SqsReaderController

  def initialize
    super QueueNames::CONVERSION_TRACKING
  end

  private

  def on_message(message)
    json = JSON.parse(message.body)
    click = Click.deserialize(json['click'])
    installed_at_epoch = json['install_timestamp']

    offer = Offer.find_in_cache(click.offer_id, true)
    currency = Currency.find_in_cache(click.currency_id, true)

    if click.installed_at? || (offer.item_type != 'GenericOffer' && click.clicked_at < (Time.zone.now - 2.days)) || click.block_reason?
      return
    end

    # Try to stop Playdom users from click-frauding (specifically from Mobsters: Big Apple)
    if currency.callback_url == Currency::PLAYDOM_CALLBACK_URL && click.publisher_user_id !~ /^(F|M|P)[0-9]+$/
      click.block_reason = "InvalidPlaydomUserId"
      click.serial_save
      return
    end

    publisher_user = PublisherUser.new(:key => "#{click.publisher_app_id}.#{click.publisher_user_id}")
    unless publisher_user.update!(click.udid)
      click.block_reason = "TooManyUdidsForPublisherUserId"
      click.serial_save
      return
    end

    # Do not reward if user has installed this app for the same publisher user id on another device
    unless offer.multi_complete?
      other_udids = publisher_user.udids - [ click.udid ]
      other_udids.each do |udid|
        device = Device.new(:key => udid)
        if device.has_app?(click.advertiser_app_id)
          click.block_reason = "AlreadyRewardedForPublisherUserId (UDID=#{udid})"
          click.serial_save
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

    device.set_publisher_user_id!(click.publisher_app_id, click.publisher_user_id)

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

    reward_message = reward.serialize(:attributes_only => true)
    Sqs.send_message(QueueNames::SEND_CURRENCY, reward_message) if offer.rewarded? && currency.callback_url != Currency::NO_CALLBACK_URL
    Sqs.send_message(QueueNames::CREATE_CONVERSIONS, reward_message)

    reward.update_realtime_stats rescue nil # we don't really care if this produces an error

    click.put('installed_at', installed_at_epoch)
    click.serial_save

    web_request = WebRequest.new(:time => Time.zone.at(installed_at_epoch.to_f))
    web_request.path              = 'reward'
    web_request.type              = reward.type
    web_request.publisher_app_id  = reward.publisher_app_id
    web_request.advertiser_app_id = reward.advertiser_app_id
    web_request.displayer_app_id  = reward.displayer_app_id
    web_request.offer_id          = reward.offer_id
    web_request.currency_id       = reward.currency_id
    web_request.publisher_user_id = reward.publisher_user_id
    web_request.advertiser_amount = reward.advertiser_amount
    web_request.publisher_amount  = reward.publisher_amount
    web_request.displayer_amount  = reward.displayer_amount
    web_request.tapjoy_amount     = reward.tapjoy_amount
    web_request.currency_reward   = reward.currency_reward
    web_request.source            = reward.source
    web_request.udid              = reward.udid
    web_request.country           = reward.country
    web_request.exp               = reward.exp
    web_request.viewed_at         = reward.viewed_at
    web_request.save
  end
end
