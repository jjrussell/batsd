class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
  end

  private

  def on_message(message)
    message = JSON.parse(message.to_s)
    gamer = Gamer.find(message['gamer_id'])

    offer_data = {}
    device, gamer_device, external_publisher = ExternalPublisher.most_recently_run_for_gamer(gamer)
    if external_publisher
      currency = external_publisher.currencies.first
      offerwall_url = external_publisher.get_offerwall_url(device, currency, message['accept_language_str'], message['user_agent_str'])

      sess = Patron::Session.new
      offerwall_data = sess.get(offerwall_url).body
      offer_data[currency[:id]] = JSON.parse(offerwall_data)
    end

    GamesMarketingMailer.deliver_welcome(gamer, games_confirm_url(:token => gamer.confirmation_token), gamer_device, offer_data)
  end

end
