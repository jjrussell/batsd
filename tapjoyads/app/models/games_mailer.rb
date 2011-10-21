class GamesMailer < ActionMailer::Base
  include SendGrid

  self.delivery_method = :smtp
  self.smtp_settings = {
    :address => "smtp.sendgrid.net",
    :port => 587,
    :domain => "tapjoy.com",
    :authentication => :plain,
    :user_name => "erictipton",
    :password => "shufflethebits"
  }

  sendgrid_category :use_subject_lines
  sendgrid_enable :clicktrack, :opentrack

  def gamer_confirmation(gamer, confirmation_link)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Welcome to Tapjoy Games!"
    content_type 'text/html'
    body :confirmation_link => confirmation_link, :linked => gamer.devices.any?
  end

  def password_reset(gamer, reset_link)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients gamer.email
    subject "Password Reset Request - Tapjoy Games"
    content_type 'text/html'
    body :reset_link => reset_link
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
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Tapjoy - Link Device"
  end

  def invite(gamer_name, recipients_email, link)
    from "#{gamer_name} <noreply@tapjoy.com>"
    recipients recipients_email
    sendgrid_category "Invite"
    subject "#{gamer_name} has invited you to join Tapjoy"
    content_type 'text/html'
    body(:ios_link => ios_link, :android_link => android_link)
  end
end
