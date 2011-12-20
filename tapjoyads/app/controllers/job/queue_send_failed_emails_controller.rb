class Job::QueueSendFailedEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_EMAILS
  end

  private

  def on_message(message)
    message = Marshal.restore(Base64::decode64(message.body))

    # TODO: remove ternary and 'else' values once we're sure every new message is a hash
    mailer = (message.is_a? Hash) ? message[:mailer_name].constantize : ActionMailer::Base
    mail = (message.is_a? Hash) ? message[:mail] : message

    begin
      mailer.deliver_without_rescue_errors(mail)
    rescue AWS::SimpleEmailService::Errors::MessageRejected => e
      recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a
      if e.to_s =~ /Address blacklisted/ && recipients.size == 1
        save_failed_email(mail)
      else
        raise e
      end
    rescue AWS::SimpleEmailService::Errors::InvalidParameterValue => e
      if e.to_s =~ /Missing required header 'To'/
        save_failed_email(mail)
      else
        raise e
      end
    end
  end

  def save_failed_email(mail)
    failed_email = FailedEmail.new(:load => false)
    failed_email.fill(mail)
    failed_email.serial_save
  end

end
