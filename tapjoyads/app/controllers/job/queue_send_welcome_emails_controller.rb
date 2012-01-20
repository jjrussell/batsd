class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
  end

  private

  def on_message(message)
    device_info = Marshal.restore(Base64::decode64(message.body))

    gamer = Gamer.find(device_info.delete(:gamer_id))

    mail = GamesMarketingMailer.create_welcome_email(gamer, device_info)
    GamesMarketingMailer.deliver(mail) if EmailVerifier.check_recipients(mail)
  end

end
