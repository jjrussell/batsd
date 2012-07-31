class TransactionalMailer  ## Soon to extend ExactTargetMailer

  ET_TJM_WELCOME_EMAIL_ID = 'tjm_welcome_en'

  def welcome_email(gamer, device_info = {})
    setup_emails(gamer, device_info)
    detailed_email = true
    @linked &&= detailed_email
    device_info[:content] = @detailed_email ? 'detailed' : 'confirm_only'
    device_info[:token] = gamer.confirmation_token
    @confirmation_url = "#{WEBSITE_URL}/confirm?token=#{gamer.confirmation_token}"

    # Gather required data for the ET data extension
    data = {
      :android_device           => @android_device ? 1 : 0,
      :confirmation_url         => @confirmation_url,
      :linked                   => @linked ? 1 : 0,
      :facebook_signup          => @facebook_signup ? 1 : 0,
      :show_detailed_email      => detailed_email ? 1 : 0,
      :show_offer_data          => @offer_data.any? ? 1 : 0,
      :show_recommendations     => @recommendations.any? ? 1 : 0,
    }
    options = {
      :account_id     => ExactTargetApi::TAPJOY_CONSUMER_ACCOUNT_ID,
    }

    # Gather optional data for the ET data extension
    if @offer_data.any?
      data[:currency_id]        = @offer_data.keys.first
      data[:currency_name]      = @offer_data.first.second["CurrencyName"]
      data[:publisher_icon_url] = @offer_data.first.second[:external_publisher].get_icon_url
      data[:publisher_app_name] = @offer_data.first.second[:external_publisher].app_name

      offer_array = @offer_data.first.second["OfferArray"]
      if offer_array.first.present?
        data[:offer1_icon_url]  = offer_array.first["IconURL"]
        data[:offer1_name]      = offer_array.first["Name"]
        data[:offer1_type]      = offer_array.first["Type"]
        data[:offer1_amount]    = offer_array.first["Amount"]
      end
      if offer_array.second.present?
        data[:offer2_icon_url]  = offer_array.second["IconURL"]
        data[:offer2_name]      = offer_array.second["Name"]
        data[:offer2_type]      = offer_array.second["Type"]
        data[:offer2_amount]    = offer_array.second["Amount"]
      end
      if offer_array.third.present?
        data[:offer3_icon_url]  = offer_array.third["IconURL"]
        data[:offer3_name]      = offer_array.third["Name"]
        data[:offer3_type]      = offer_array.third["Type"]
        data[:offer3_amount]    = offer_array.third["Amount"]
      end
    end
    if @recommendations.any?
      if @recommendations.first.present?
        data[:recommendation1_icon_url] = @recommendations.first.icon_url
        data[:recommendation1_name]     = @recommendations.first.name
      end
      if @recommendations.second.present?
        data[:recommendation2_icon_url] = @recommendations.second.icon_url
        data[:recommendation2_name]     = @recommendations.second.name
      end
      if @recommendations.third.present?
        data[:recommendation3_icon_url] = @recommendations.third.icon_url
        data[:recommendation3_name]     = @recommendations.third.name
      end
    end

    # Make ExactTarget do the rest of the work
    et = ExactTargetApi.new
    status = et.send_triggered_email(gamer.email, ET_TJM_WELCOME_EMAIL_ID, data, options)
  end

  private

  def setup_emails(gamer, device_info = {})
    @offer_data = {}
    device, @gamer_device, external_publisher = ExternalPublisher.most_recently_run_for_gamer(gamer)
    if external_publisher
      currency = external_publisher.currencies.first
      offerwall_url = external_publisher.get_offerwall_url(device, currency, device_info[:accept_language_str], device_info[:user_agent_str], nil, true)

      sess = Patron::Session.new
      response = sess.get(offerwall_url)
      raise "Error getting offerwall data HTTP code: #{ response.status }" unless response.status == 200
      @offer_data[currency[:id]] = JSON.parse(response.body).merge(:external_publisher => external_publisher)
    end

    @gamer_device ||= gamer.gamer_devices.first
    selected_devices = device_info[:selected_devices] || []
    @linked = @gamer_device.present?
    @android_device = @linked ? (@gamer_device.device_type == 'android') : !selected_devices.include?('ios')

    device = Device.new(:key => @linked ? @gamer_device.device_id : nil)
    @recommendations = device.recommendations(device_info.slice(:device_type, :geoip_data, :os_version))
    @facebook_signup = gamer.facebook_id.present?
    @gamer_email = gamer.email if @facebook_signup
  end
end
