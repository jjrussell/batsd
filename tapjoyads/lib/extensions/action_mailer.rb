class ActionMailer::Base

  def deliver_with_rescue_errors!(mail = @mail)
    begin
      deliver_without_rescue_errors!(mail)
    rescue Exception => e
      message = Base64::encode64(Marshal.dump(mail))
      Sqs.send_message(QueueNames::FAILED_EMAILS, message)
      Notifier.alert_new_relic(e.class, e.message)
    end
  end
  alias_method_chain :deliver!, :rescue_errors

  def self.deliver_without_rescue_errors(mail)
    new.deliver_without_rescue_errors!(mail)
  end

end
