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
  
  def email_signup(to_email, confirm_code, currency_name, publisher_app_name, amount)
    from "noreply@tapjoy.com"
    recipients to_email
    subject "Confirmation email - get #{amount} #{publisher_app_name} #{currency_name}"
    url = "http://ws.tapjoyads.com/list_signup/confirm?code=#{confirm_code}"
    body :url => confirm_code, :currency => currency_name, :publisher_app_name => publisher_app_name, :amount => amount
  end
end
