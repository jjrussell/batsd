class GamesMailer < ActionMailer::Base
  def feedback(gamer, content, user_agent, device_id)
    from 'Tapjoy <noreply@tapjoy.com>'
    reply_to gamer.email
    recipients "customerservice@tapjoy.com"
    subject "User Feedback - Tapjoy"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end

  def report_bug(gamer, content, user_agent, device_id)
    from 'Tapjoy <noreply@tapjoy.com>'
    reply_to gamer.email
    recipients "mobilehelp@tapjoy.com"
    subject "Bug Report - Tapjoy"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end

  def contact_support(gamer, content, user_agent, device_id)
    from 'Tapjoy <noreply@tapjoy.com>'
    reply_to gamer.email
    recipients "mobilehelp@tapjoy.com"
    subject "User Support - Tapjoy"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end

  def password_reset(gamer, reset_link)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients gamer.email
    subject "Password Reset Request - Tapjoy"
    content_type 'text/html'
    body :reset_link => reset_link
  end

  def link_device(gamer, ios_link, android_link)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Tapjoy - Link Device"
    content_type 'text/html'
    body(:ios_link => ios_link, :android_link => android_link)
  end

  def delete_gamer(gamer)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Tapjoy - Delete Account Confirmation"
    content_type 'text/html'
    body(:name => gamer.get_gamer_name)
  end
end
