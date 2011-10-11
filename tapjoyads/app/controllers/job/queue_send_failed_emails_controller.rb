class Job::QueueSendFailedEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::FAILED_EMAILS
  end

  private

  def on_message(message)
    mail = Marshal.restore(Base64::decode64(message.to_s))

    begin
      ActionMailer::Base.deliver_without_rescue_errors(mail)
    rescue AWS::SimpleEmailService::Errors::MessageRejected => e
      recipients = mail.to.to_a + mail.cc.to_a + mail.bcc.to_a
      if e.to_s =~ /Address blacklisted/ && recipients.size == 1
        Rails.logger.info "Address blackslisted: #{recipients.first}"
      else
        raise e
      end
    end
  end

end
