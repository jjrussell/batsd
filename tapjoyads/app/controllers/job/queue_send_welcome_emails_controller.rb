class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
    @retry_on_false_return_value = true
  end

  private

  def on_message(message)
    message = JSON.parse(message.to_s)
    gamer = Gamer.find(message['gamer_id'])

    # give the gamer time to link a device
    if gamer.created_at >= (Time.zone.now - 5.minutes)
      return false # retry later
    end

    offer_data = {}
    device, gamer_device, external_publisher = ExternalPublisher.most_recently_run_for_gamer(gamer)
    if external_publisher
      currency = external_publisher.currencies.first
      offerwall_url = external_publisher.get_offerwall_url(device, currency, message['accept_language_str'], message['user_agent_str'])

      sess = Patron::Session.new
      response = sess.get(offerwall_url)
      raise "Error getting offerwall data" unless response.status == 200
      offer_data[currency[:id]] = JSON.parse(response.body).merge(:external_publisher => external_publisher)
    end

    editors_picks = offer_data.any? ? [] : EditorsPick.cached_active(message['using_android'] ? 'android' : 'ios')

    confirm_url = "#{TJGAMES_URL}/confirm?token=#{CGI.escape(gamer.confirmation_token)}"
    GamesMarketingMailer.deliver_welcome_email(gamer, confirm_url, gamer_device, offer_data, editors_picks)
    true
  end

end
