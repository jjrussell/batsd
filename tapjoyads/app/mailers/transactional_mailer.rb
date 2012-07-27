class TransactionalMailer  ## Soon to extend ExactTargetMailer

  ET_TJM_WELCOME_EMAIL_ID = 'tjm_welcome_en'

  def welcome_email(gamer, device_info = {})
    setup_emails(gamer, device_info)
    detailed_email = true
    @linked &&= detailed_email
    device_info[:content] = @detailed_email ? 'detailed' : 'confirm_only'
    device_info[:token] = gamer.confirmation_token
    @confirmation_url = "#{WEBSITE_URL}/confirm?token=#{gamer.confirmation_token}"

    # mail :to => gamer.email, :from => 'Tapjoy <noreply@tapjoy.com>', :subject => 'Welcome to Tapjoy!'

    # Gather dynamic data for ExactTarget's email template
    data = {
      :android_device           => @android_device ? 1 : 0,
      :confirmation_url         => @confirmation_url,
      :currency_id              => "CURRENCY_ID",
      :currency_name            => "GOLD COINS",
      :facebook_signup          => @facebook_signup ? 1 : 0,
      :gamer_email              => gamer.email,
      :linked                   => @linked ? 1 : 0,
      :publisher_icon_url       => "https://s3.amazonaws.com/tapjoy/icons/SIZE/ICON_ID.jpg",
      :publisher_app_name       => "PUBLISHER APP NAME",
      :recommendation1_icon_url => "https://s3.amazonaws.com/tapjoy/icons/SIZE/AN_APP.jpg",
      :recommendation1_name     => "An App",
      :recommendation2_icon_url => "https://s3.amazonaws.com/tapjoy/icons/SIZE/ANOTHER_APP.jpg",
      :recommendation2_name     => "Another App",
      :offer1_icon_url          => "https://s3.amazonaws.com/tapjoy/icons/SIZE/AN_OFFER.jpg",
      :offer1_name              => "An Offer",
      :offer1_type              => "App",
      :offer1_amount            => 10,
      :offer2_icon_url          => "https://s3.amazonaws.com/tapjoy/icons/SIZE/ANOTHER_OFFER.jpg",
      :offer2_name              => "Another Offer",
      :offer2_type              => "NotAnApp",
      :offer2_amount            => 20,
      :offer3_icon_url          => "https://s3.amazonaws.com/tapjoy/icons/SIZE/YET_ANOTHER_OFFER.jpg",
      :offer3_name              => "Yet Another Offer",
      :offer3_type              => "App",
      :offer3_amount            => 300,
      :show_detailed_email      => detailed_email ? 1 : 0,
      :show_offer_data          => @offer_data.any? ? 1 : 0,
      :show_recommendations     => @recommendations.any? ? 1 : 0,
    }
    options = {
      :account_id     => ExactTargetApi::TAPJOY_CONSUMER_ACCOUNT_ID,
      # :priority       => "High",
    }

    Rails.logger.info "Data: #{data.inspect}"
    et = ExactTargetApi.new
    et.send_triggered_email(gamer.email, ET_TJM_WELCOME_EMAIL_ID, data, options)
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
