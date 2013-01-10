class Job::QueueSendFailedEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_EMAILS
  end

  private

  def on_message(message)
    message = Marshal.restore_with_ensure_utf8(Base64::decode64(message.body))

    mailer = message[:mailer_name].constantize
    mail = Mail::Message.from_yaml(message[:mail_yaml])

    begin
      mailer.deliver_without_rescue_errors(mail)
    rescue AWS::SimpleEmailService::Errors::MessageRejected => e
      recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a - [ RECEIPT_EMAIL ]
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
    failed_email.save
  end

end
