class GamesMailer < ActionMailer::Base
  
  def gamer_confirmation(gamer, confirmation_link)
    from "noreply@tapjoy.com"
    recipients gamer.email
    subject "Welcome to Tapjoy Games!"
    content_type 'text/html'
    body :confirmation_link => confirmation_link, :linked => gamer.udid?
  end
  
  def password_reset(gamer, reset_link)
    from "mobilehelp@tapjoy.com"
    recipients gamer.email
    subject "Password Reset Request - Tapjoy Games"
    content_type 'text/html'
    body :reset_link => reset_link
  end
  
  def feedback(gamer, content, user_agent)
    from gamer.email
    recipients "feedback@tapjoy.com"
    subject "User Feedback - Tapjoy Games"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :user_agent => user_agent)
  end
  
  def report_bug(gamer, content, user_agent, device_id)
    from gamer.email
    recipients "mobilehelp@tapjoy.com"
    subject "Bug Report - Tapjoy Games"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end
  
  def contact_support(gamer, content, user_agent, device_id)
    from gamer.email
    recipients "mobilehelp@tapjoy.com"
    subject "User Support - Tapjoy Games"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end
  
end
