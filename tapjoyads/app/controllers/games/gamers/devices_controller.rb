class Games::Gamers::DevicesController < GamesController

  def new
    if current_gamer.present?
      send_file("#{RAILS_ROOT}/data/TapjoyGamesProfile.mobileconfig", :filename => 'TapjoyGamesProfile.mobileconfig', :disposition => 'inline', :type => :mobileconfig)
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

    mac_address = mac_address.present? ? mac_address.downcase.gsub(/:/,"") : nil
    data = {
      :udid              => udid,
      :product           => product,
      :version           => version,
      :mac_address       => mac_address,
      :platform          => 'ios'
    }
    redirect_to finalize_games_gamer_device_path(:data => SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)), :status => 301
  rescue Exception => e
    Notifier.alert_new_relic(e.class, e.message, request, params)
    flash[:error] = "Error linking device. Please try again."
    redirect_to games_root_path, :status => 301
  end

  def finalize
    if current_gamer.present?
      redirect_to games_root_path unless params[:data].present?
      data = SymmetricCrypto.decrypt_object(params[:data], SYMMETRIC_CRYPTO_SECRET)

      device = Device.new(:key => data[:udid])
      device.product = data[:product]
      device.version = data[:version]
      device.mac_address = data[:mac_address] if data[:mac_address].present?
      device.platform = data[:platform]

      cookies[:data] = { :value => params[:data], :expires => 1.year.from_now } if params[:data].present?

      if current_gamer.devices.create(:device => device)
        click = Click.new :key => "#{device.key}.#{TAPJOY_GAMES_REGISTRATION_OFFER_ID}"
        if click.rewardable?
          current_gamer.reward_click(click)
        else
          device.set_last_run_time!(TAPJOY_GAMES_REGISTRATION_OFFER_ID)
        end
        redirect_to games_root_path(:register_device => true)
      else
        flash[:error] = "Error linking device. Please try again."
        redirect_to games_root_path
      end
    else
      flash[:error] = "Please log in to link your device. You must have cookies enabled."
      redirect_to games_login_path(:data => params[:data])
    end
  end
end
