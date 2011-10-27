class GamesMailer < ActionMailer::Base

  def gamer_confirmation(gamer, confirmation_link)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Welcome to Tapjoy!"
    content_type 'text/html'
    if gamer.gamer_devices.any? && gamer.gamer_devices.first.device_type == 'android'
      device_type = :android
    else
      device_type = :iphone
    end
    body :confirmation_link => confirmation_link, :linked => gamer.gamer_devices.any?, :device_type => device_type
  end

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
    puts ios_link
    puts android_link
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Tapjoy - Link Device"
    content_type 'text/html'
    body(:ios_link => ios_link, :android_link => android_link)
  end
end
