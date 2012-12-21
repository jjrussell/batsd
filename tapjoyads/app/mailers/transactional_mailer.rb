class TransactionalMailer  ## Soon to extend ExactTargetMailer
  class ShouldRetryError < StandardError; end;

  ET_TJM_WELCOME_EMAIL_ID = 'tjm_welcome_en'

  def welcome_email(gamer, device_info = {})
    setup_for_tjm_welcome_email(gamer, device_info)

    @detailed_email = @facebook_signup ? true : false
    @linked &&= @detailed_email
    device_info[:content] = @detailed_email ? 'detailed' : 'confirm_only'
    device_info[:id] = gamer.confirmation_token
    EmailConfirmData.create!(device_info)
    @confirmation_url = "#{WEBSITE_URL}/confirm?token=#{gamer.confirmation_token}"

    build_data_for_tjm_welcome_email

    ##
    ## TODO: Move mail triggering logic and response code checking to ExactTargetMailer class
    ##

    ##
    ## TODO: Add mail_safe style checks to keep dev emails from escaping into the wild
    ##

    # Make ExactTarget do the rest of the work
    send_using_exact_target(gamer)
  end

  def post_confirm_email(gamer, device_info = {})
    setup_for_tjm_welcome_email(gamer, device_info)

    @detailed_email = true

    build_data_for_tjm_welcome_email

    ##
    ## TODO: Move mail triggering logic and response to ExactTargetMailer class
    ##

    ##
    ## TODO: Add mail_safe style checks to keep dev emails from escaping into the wild
    ##

    # Make ExactTarget do the rest of the work
    send_using_exact_target(gamer)
  end

  private


  def send_using_exact_target(gamer)
    et = ExactTargetApi.new
    response = et.send_triggered_email(gamer.email, ET_TJM_WELCOME_EMAIL_ID, @data, @options)
    unless response[:status_code] == 'OK'
      # They gave us a bogus email address
      if response[:error_code].to_i == 180008
        record_invalid_email(gamer)
      else
        # Something unexpected happened
        raise "Error sending triggered email; Details: #{ response.inspect }" unless response[:status_code] == 'OK'
      end
    end
    response
  end

  def record_invalid_email(gamer)
    if gamer.class==Hash
      params = {:email => gamer.email}
      post_invalid_email_to_tjm(sign!(params))
    else
      gamer.update_attributes!(:email_invalid => true)
    end
  end

  def post_invalid_email_to_tjm(signed_params)
    url = "#{WEBSITE_URL}/api/data/invalid_emails"
    download_options = {:timeout => 5.seconds, :return_response => true}
    begin
      response = Downloader.post(url, signed_params, download_options)
      raise ShouldRetryError if response.status.to_i >= 500
    rescue Patron::TimeoutError, ShouldRetryError
      Downloader.queue_with_retry_until_successful(url, :post, signed_params, download_options)
    end
  end


  def sign!(params)
    Signage::ExpiringSignature.new('hmac_sha256', Rails.configuration.tapjoy_api_key).sign_hash!(params)
  end


  ##
  ## TODO: Refactor this to make more sense for ExactTarget integration
  ##
  def build_data_for_tjm_welcome_email
    # Gather required data for the ET data extension
    offer_array = (@offer_data.present? && @offer_data.first.second["OfferArray"].present?) ? @offer_data.first.second["OfferArray"] : []
    @data = {
      :android_device           => @android_device ? 1 : 0,
      :confirmation_url         => @confirmation_url,
      :linked                   => @linked ? 1 : 0,
      :facebook_signup          => @facebook_signup ? 1 : 0,
      :show_detailed_email      => @detailed_email ? 1 : 0,
      :show_offer_data          => offer_array.any? ? 1 : 0,
      :show_recommendations     => @recommendations.any? ? 1 : 0,
    }
    @options = {
      :account_id     => ExactTargetApi::TAPJOY_CONSUMER_ACCOUNT_ID,
    }

    # Gather optional data for the ET data extension
    if @offer_data.any?
      @data[:currency_id]        = @offer_data.keys.first
      @data[:currency_name]      = @offer_data.first.second["CurrencyName"]
      @data[:publisher_icon_url] = @offer_data.first.second[:external_publisher].get_icon_url
      @data[:publisher_app_name] = @offer_data.first.second[:external_publisher].app_name

      if offer_array.first.present?
        @data[:offer1_icon_url]  = offer_array.first["IconURL"]
        @data[:offer1_name]      = offer_array.first["Name"]
        @data[:offer1_type]      = offer_array.first["Type"]
        @data[:offer1_amount]    = offer_array.first["Amount"]
      end
      if offer_array.second.present?
        @data[:offer2_icon_url]  = offer_array.second["IconURL"]
        @data[:offer2_name]      = offer_array.second["Name"]
        @data[:offer2_type]      = offer_array.second["Type"]
        @data[:offer2_amount]    = offer_array.second["Amount"]
      end
      if offer_array.third.present?
        @data[:offer3_icon_url]  = offer_array.third["IconURL"]
        @data[:offer3_name]      = offer_array.third["Name"]
        @data[:offer3_type]      = offer_array.third["Type"]
        @data[:offer3_amount]    = offer_array.third["Amount"]
      end
    end
    if @recommendations.any?
      if @recommendations.first.present?
        @data[:recommendation1_icon_url] = @recommendations.first.icon_url
        @data[:recommendation1_name]     = @recommendations.first.name
      end
      if @recommendations.second.present?
        @data[:recommendation2_icon_url] = @recommendations.second.icon_url
        @data[:recommendation2_name]     = @recommendations.second.name
      end
      if @recommendations.third.present?
        @data[:recommendation3_icon_url] = @recommendations.third.icon_url
        @data[:recommendation3_name]     = @recommendations.third.name
      end
    end
  end

  ##
  ## TODO: Refactor this to make more sense for ExactTarget integration
  ##
  def setup_for_tjm_welcome_email(gamer, device_info = {})
    @offer_data = {}
    setup_for_tjm_welcome_email_without_using_tjm_tables(gamer,device_info) and return if gamer.class==Hash

    device, gamer_device, external_publisher = ExternalPublisher.most_recently_run_for_gamer(gamer)
    get_offerwall(device, device_info, external_publisher) if external_publisher
    gamer_device ||= gamer.gamer_devices.first
    selected_devices = device_info[:selected_devices] || []
    @linked = gamer_device.present?
    @android_device = @linked ? (gamer_device.device_type == 'android') : !selected_devices.include?('ios')
    device_key = @linked ? gamer_device.device_id : nil
    device = get_device(device_key )
    @recommendations = device.new_record? ? [] : device.recommendations(device_info.slice(:device_type, :geoip_data, :os_version))
    @facebook_signup = gamer.facebook_id.present?
    @gamer_email = gamer.email if @facebook_signup

  end

  def get_device(key)
    Device.new(:key => key)
  end

  def get_offerwall(device, device_info, external_publisher)
    currency = external_publisher.currencies.first
    offerwall_url = external_publisher.get_offerwall_url(device, currency, device_info[:accept_language_str], device_info[:user_agent_str], nil, true)
    response = Downloader.get(offerwall_url, :return_response => true)
    raise "Error getting offerwall data HTTP code: #{ response.status }" unless response.status == 200
    @offer_data[currency[:id]] = JSON.parse(response.body).merge(:external_publisher => external_publisher)
  end

  def setup_for_tjm_welcome_email_without_using_tjm_tables(gamer, device_info = {})
    arr = [nil, nil, nil]
    latest_run_time = 0
    gamer_devices = gamer[:gamer_devices]  # [{:id=>..., :type=>...},...,...]

    gamer_devices.try (:each) do |device_hash|    #{:id=> Device#key, :type=>GamerDevice#device_type}
      device = Device.new(:key => device_hash[:id])
      external_publisher = ExternalPublisher.load_all_for_device(device).first
      next unless external_publisher.present?
      latest_run_time = [latest_run_time, external_publisher.last_run_time].max
      if latest_run_time == external_publisher.last_run_time
        arr = [device, device_hash, external_publisher]
      end
    end
    device, gamer_device, external_publisher = arr

    get_offerwall(device, device_info, external_publisher) if external_publisher

    gamer_device ||= gamer_devices.first
    selected_devices = device_info[:selected_devices] || []
    @linked = gamer_device.present?
    @android_device = @linked ? (gamer_device[:type] == 'android') : !selected_devices.include?('ios')
    device_key = @linked ? gamer_device[:id] : nil

    device = get_device( device_key)
    @recommendations = device.new_record? ? [] : device.recommendations(device_info.slice(:device_type, :geoip_data, :os_version))
    @facebook_signup = gamer[:facebook_id].present?
    @gamer_email = gamer[:email] if @facebook_signup
    true
  end
end
