class ActionMailer::Base

  def deliver_with_rescue_errors!(mail = @mail)
    begin
      deliver_without_rescue_errors!(mail)
    rescue Exception => e
      message = Base64::encode64(Marshal.dump({:mail => mail, :mailer_name => self.class.name}))
      Sqs.send_message(QueueNames::FAILED_EMAILS, message)
      Notifier.alert_new_relic(e.class, e.message)
    end
  end

  def deliver_with_receipt!(mail = @mail)
    # let's avoid paying for sending emails to ourselves (RECEIPT_EMAIL), via sendgrid
    unless self.smtp_settings[:address] == 'smtp.sendgrid.net'
      if mail.bcc
        mail.bcc += [ RECEIPT_EMAIL ]
      else
        mail.bcc = RECEIPT_EMAIL
      end
    end
    deliver_without_receipt!(mail)
  end

  alias_method_chain :deliver!, :rescue_errors
  alias_method_chain :deliver!, :receipt

  def self.deliver_without_rescue_errors(mail)
    new.deliver_without_rescue_errors!(mail)
  end

end
