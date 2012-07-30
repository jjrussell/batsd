class TransactionalMailer  ## Soon to extend ExactTargetMailer

  ET_TJM_WELCOME_EMAIL_ID = 'tjm_welcome_en'

  def welcome_email(gamer, device_info = {})
    setup_emails(gamer, device_info)
    detailed_email = true
    @linked &&= detailed_email
    device_info[:content] = @detailed_email ? 'detailed' : 'confirm_only'
    device_info[:token] = gamer.confirmation_token
    @confirmation_url = "#{WEBSITE_URL}/confirm?token=#{gamer.confirmation_token}"

    # Gather dynamic data for ExactTarget's email template
    data = {
      :android_device           => @android_device ? 1 : 0,
      :confirmation_url         => @confirmation_url,
      :currency_id              => @offer_data.any? ? @offer_data.keys.first : '',
      :currency_name            => @offer_data.any? ? @offer_data.first.second["CurrencyName"] : '',
      :facebook_signup          => @facebook_signup ? 1 : 0,
      :gamer_email              => gamer.email,
      :linked                   => @linked ? 1 : 0,
      :publisher_icon_url       => @offer_data.any? ? @offer_data.first.second[:external_publisher].get_icon_url : '',
      :publisher_app_name       => @offer_data.any? ? @offer_data.first.second[:external_publisher].app_name : '',
      :recommendation1_icon_url => @recommendations.any? && @recommendations[0].present? ? @recommendations[0].icon_url : '',
      :recommendation1_name     => @recommendations.any? && @recommendations[0].present? ? @recommendations[0].name : '',
      :recommendation2_icon_url => @recommendations.any? && @recommendations[1].present? ? @recommendations[1].icon_url : '',
      :recommendation2_name     => @recommendations.any? && @recommendations[1].present? ? @recommendations[1].name : '',
      :recommendation3_icon_url => @recommendations.any? && @recommendations[2].present? ? @recommendations[2].icon_url : '',
      :recommendation3_name     => @recommendations.any? && @recommendations[2].present? ? @recommendations[2].name : '',
      :offer1_icon_url          => @offer_data.any? && @offer_data.first.second["OfferArray"][0].present? ? @offer_data.first.second["OfferArray"][0]["IconURL"]  : '',
      :offer1_name              => @offer_data.any? && @offer_data.first.second["OfferArray"][0].present? ? @offer_data.first.second["OfferArray"][0]["Name"]  : '',
      :offer1_type              => @offer_data.any? && @offer_data.first.second["OfferArray"][0].present? ? @offer_data.first.second["OfferArray"][0]["Type"]  : '',
      :offer1_amount            => @offer_data.any? && @offer_data.first.second["OfferArray"][0].present? ? @offer_data.first.second["OfferArray"][0]["Amount"]  : '',
      :offer2_icon_url          => @offer_data.any? && @offer_data.first.second["OfferArray"][1].present? ? @offer_data.first.second["OfferArray"][1]["IconURL"]  : '',
      :offer2_name              => @offer_data.any? && @offer_data.first.second["OfferArray"][1].present? ? @offer_data.first.second["OfferArray"][1]["Name"]  : '',
      :offer2_type              => @offer_data.any? && @offer_data.first.second["OfferArray"][1].present? ? @offer_data.first.second["OfferArray"][1]["Type"]  : '',
      :offer2_amount            => @offer_data.any? && @offer_data.first.second["OfferArray"][1].present? ? @offer_data.first.second["OfferArray"][1]["Amount"]  : '',
      :offer3_icon_url          => @offer_data.any? && @offer_data.first.second["OfferArray"][2].present? ? @offer_data.first.second["OfferArray"][2]["IconURL"]  : '',
      :offer3_name              => @offer_data.any? && @offer_data.first.second["OfferArray"][2].present? ? @offer_data.first.second["OfferArray"][2]["Name"]  : '',
      :offer3_type              => @offer_data.any? && @offer_data.first.second["OfferArray"][2].present? ? @offer_data.first.second["OfferArray"][2]["Type"]  : '',
      :offer3_amount            => @offer_data.any? && @offer_data.first.second["OfferArray"][2].present? ? @offer_data.first.second["OfferArray"][2]["Amount"]  : '',
      :show_detailed_email      => detailed_email ? 1 : 0,
      :show_offer_data          => @offer_data.any? ? 1 : 0,
      :show_recommendations     => @recommendations.any? ? 1 : 0,
    }
    options = {
      :account_id     => ExactTargetApi::TAPJOY_CONSUMER_ACCOUNT_ID,
    }

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
