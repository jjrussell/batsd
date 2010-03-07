class TapjoyMailer < ActionMailer::Base
  
  def newrelic_alert(error)
    from "admin@tapjoy.com"
    recipients "dev@tapjoy.com"
    subject "NewRelic Error: #{error.inspect}"
    body(:error => error)
  end
  
  def sms_sent(phone, message)
    from "admin@tapjoy.com"
    recipients "dev@tapjoy.com"
    subject "An SMS has been sent"
    body :text => "An sms has been sent to #{phone}, with the message: #{message}"
  end
end
