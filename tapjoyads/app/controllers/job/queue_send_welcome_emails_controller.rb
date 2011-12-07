class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
  end

  private

  def on_message(message)
    message = JSON.parse(message.body)

    gamer = Gamer.find(message['gamer_id'])
    device_info = { :accept_language => message['accept_language_str'], :user_agent => message['user_agent_str'], :is_android => message['using_android'] }

    GamesMarketingMailer.deliver_welcome_email(gamer, device_info)
  end

end
