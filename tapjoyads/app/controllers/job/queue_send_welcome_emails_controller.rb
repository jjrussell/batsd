class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
  end

  private

  def on_message(message)
    message = JSON.parse(message.body)

    gamer = Gamer.find(message.delete('gamer_id'))
    device_info = message.symbolize_keys!

    GamesMarketingMailer.deliver_welcome_email(gamer, device_info)
  end

end
