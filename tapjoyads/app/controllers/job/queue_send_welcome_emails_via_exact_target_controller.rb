class Job::QueueSendWelcomeEmailsViaExactTargetController < Job::SqsReaderController

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
    gamer = {}
    gamer[:facebook_id]         = device_info.delete(:facebook_id)
    gamer[:email]               = device_info.delete(:email)
    gamer[:confirmation_token]  = device_info.delete(:confirmation_token)
    gamer[:gamer_devices]       = device_info.delete(:gamer_devices)
    gamer.instance_eval do
      def email
        self.fetch(:email)
      end
      def confirmation_token
        self.fetch(:confirmation_token)
      end
    end

    email_type = device_info.delete(:email_type) || 'welcome'

    mailer = TransactionalMailer.new
    mailer.send("#{email_type}_email", gamer, device_info)
  end
end
