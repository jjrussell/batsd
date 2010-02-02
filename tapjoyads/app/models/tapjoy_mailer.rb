class TapjoyMailer < ActionMailer::Base
  
  def newrelic_alert(error)
    from "admin@tapjoy.com"
    recipients "dev@tapjoy.com"
    subject "NewRelic Error: #{error.inspect}"
    body(:error => error)
  end
end
