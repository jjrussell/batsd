class Games::Gamers::DevicesController < GamesController

  def new
    if current_gamer.present?
      if Rails.env.staging?
        send_file("#{Rails.root}/data/TapjoyProfile.mobileconfig.staging.unsigned", :filename => 'TapjoyProfile.mobileconfig', :disposition => 'inline', :type => :mobileconfig)
      else
        send_file("#{Rails.root}/data/TapjoyProfile.mobileconfig", :filename => 'TapjoyProfile.mobileconfig', :disposition => 'inline', :type => :mobileconfig)
      end
    else
      flash[:error] = "Please log in and try again. You must have cookies enabled."
      redirect_to games_root_path
    end
  end

  def create
    match = request.raw_post.match(/<plist.*<\/plist>/m)
    raise "Plist not present" unless match.present? && match[0].present?

    udid, product, version, mac_address = nil
    (Hpricot(match[0])/"key").each do |key|
      value = key.next_sibling.inner_text
      case key.inner_text
      when 'UDID';    udid = value
      when 'PRODUCT'; product = value
      when 'VERSION'; version = value
      when 'MAC_ADDRESS_EN0'; mac_address = value
      end
    end
    raise "Error parsing plist" if udid.blank? || product.blank? || version.blank?

    data = {
      :udid              => udid,
      :product           => product,
      :version           => version,
      :mac_address       => mac_address,
      :platform          => 'ios'
    }
    redirect_to finalize_games_gamer_device_path(:data => ObjectEncryptor.encrypt(data)), :status => 301
  rescue Exception => e
    Notifier.alert_new_relic(e.class, e.message, request, params)
    flash[:error] = "Error linking device. Please try again."
    redirect_to games_root_path, :status => 301
  end

  def finalize
    if current_gamer.present?
      redirect_to games_root_path unless params[:data].present?
      data = ObjectEncryptor.decrypt(params[:data])

      device = Device.new(:key => data[:udid])
      device.product = data[:product]
      device.version = data[:version]
      device.mac_address = data[:mac_address] if data[:mac_address].present?
      device.platform = data[:platform]

      cookies[:data] = { :value => params[:data], :expires => 1.year.from_now } if params[:data].present?

      new_device = current_gamer.devices.new(:device => device)
      if new_device.save
        click = Click.new(:key => "#{device.key}.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}")
        if click.rewardable?
          current_gamer.reward_click(click)
        else
          device.set_last_run_time!(TAPJOY_GAMES_REGISTRATION_OFFER_ID)
        end

        session[:current_device_id] = ObjectEncryptor.encrypt(device.key)

        if current_gamer.referrer.present? && !current_gamer.referrer.starts_with?('tjreferrer:')
          devices = GamerDevice.find_all_by_device_id(data[:udid])
          if devices.size == 1 && devices[0].gamer_id == current_gamer.id
            invitation_id, advertiser_app_id = ObjectEncryptor.decrypt(current_gamer.referrer).split(',')
            advertiser_app_id = TAPJOY_GAMES_INVITATION_OFFER_ID if advertiser_app_id.blank?
            referred_by_gamer = Gamer.find_by_id(current_gamer.referred_by)
            invitation = Invitation.find_by_id_and_gamer_id(invitation_id, current_gamer.referred_by)
            if advertiser_app_id && referred_by_gamer && invitation
              click = Click.new(:key => "#{current_gamer.referred_by}.#{advertiser_app_id}", :consistent => true)
              unless click.new_record?
                new_referral_count = referred_by_gamer.referral_count + 1
                referred_by_gamer.gamer_profile.update_attributes!(:referral_count => new_referral_count)
                create_sub_click(click, new_referral_count)
              end
            end
          end
        end
      else
        flash[:error] = "Error linking device. Please try again."
      end

      redirect_to games_root_path
    else
      flash[:error] = "Please log in to link your device. You must have cookies enabled."
      redirect_to games_login_path(:data => params[:data])
    end
  end

  def create_sub_click(primary_click, referral_count)
    now = Time.zone.now

    click = Click.new(:key => "#{current_gamer.referred_by}.invite[#{referral_count}]")
    click.clicked_at        = now
    click.viewed_at         = now
    click.udid              = primary_click.udid
    click.publisher_app_id  = primary_click.publisher_app_id
    click.publisher_user_id = primary_click.publisher_user_id
    click.advertiser_app_id = primary_click.advertiser_app_id
    click.displayer_app_id  = primary_click.displayer_app_id
    click.offer_id          = primary_click.offer_id
    click.currency_id       = primary_click.currency_id
    click.reward_key        = UUIDTools::UUID.random_create.to_s
    click.reward_key_2      = primary_click.reward_key_2
    click.source            = primary_click.source
    click.ip_address        = primary_click.ip_address
    click.country           = primary_click.country
    click.type              = primary_click.type
    click.advertiser_amount = primary_click.advertiser_amount
    click.publisher_amount  = primary_click.publisher_amount
    click.currency_reward   = primary_click.currency_reward
    click.displayer_amount  = primary_click.displayer_amount
    click.tapjoy_amount     = primary_click.tapjoy_amount
    click.exp               = primary_click.exp
    click.device_name       = primary_click.device_name

    click.save

    message = { :click_key => click.key, :install_timestamp => Time.zone.now.to_f.to_s }.to_json
    Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
  end
end
