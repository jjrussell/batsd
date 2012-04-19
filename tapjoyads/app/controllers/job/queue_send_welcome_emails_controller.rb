class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
  end

  private

  def on_message(message)
    device_info = Marshal.restore(Base64::decode64(message.body))

    gamer = Gamer.find(device_info.delete(:gamer_id))
    case device_info[:email_type]
    when 'post_confirm'
      mail = GamesMarketingMailer.create_post_confirm_email(gamer, device_info)
    else
      mail = GamesMarketingMailer.create_welcome_email(gamer, device_info)
    end
    GamesMarketingMailer.deliver(mail) if EmailVerifier.check_recipients(mail)
  end

end
