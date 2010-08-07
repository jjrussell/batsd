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
    content_type 'text/html'
    url = "http://ws.tapjoyads.com/list_signup/confirm?code=#{confirm_code}"
    body :url => url, :currency_name => currency_name, :publisher_app_name => publisher_app_name, :amount => amount
  end
  
  def low_conversion_rate_warning(error)
    from "admin@tapjoy.com"
    recipients "team@tapjoy.com"
    subject "Low Conversion Rate Warning!"
    body(:error => error)
  end
  
  def balance_alert(offer, potential_spend)
    from "support@tapjoy.com"
    reply_to "support@tapjoy.com"
    recipients "marketing@tapjoy.com"
    subject "Balance is getting low for #{offer.name}"
    body(:offer => offer, :potential_spend => potential_spend)
  end
  
end
