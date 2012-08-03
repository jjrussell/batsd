class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
    ##
    ## TODO: Consolidate all email queues for ET emails into one ET_EMAIL_QUEUE
    ##
  end

  private

  def on_message(message)
    ##
    ## TODO: Set up an ExactTarget status checking job to store whether or not ET is up.
    ##       Then modify this job to check the stored status before trying to send mail.
    ##
    device_info = Marshal.restore(Base64::decode64(message.body))

    gamer = Gamer.find(device_info.delete(:gamer_id))
    email_type = device_info.delete(:email_type) || 'welcome'

    mailer = TransactionalMailer.new
    mailer.send("#{email_type}_email", gamer, device_info)
  end
end
