class ActionMailer::Base

  def deliver_with_rescue_errors!(mail)
    begin
      deliver_without_rescue_errors!(mail)
    rescue Exception => e
      message = Base64::encode64(Marshal.dump({:mail => mail, :mailer_name => self.class.name}))
      Sqs.send_message(QueueNames::FAILED_EMAILS, message)
      Notifier.alert_new_relic(e.class, e.message)
    end
  end

  def deliver_with_receipt!(mail = @mail)
    if mail.bcc.present?
      mail.bcc = mail.bcc + ["email.receipts@tapjoy.com"]   # can't use << or += since #bcc isn't an array
    else
      mail.bcc = "email.receipts@tapjoy.com"
    end
    deliver_without_receipt!(mail)
  end

  alias_method_chain :deliver!, :rescue_errors
  alias_method_chain :deliver!, :receipt

  def self.deliver_without_rescue_errors(mail)
    new.deliver_without_rescue_errors!(mail)
  end

end
