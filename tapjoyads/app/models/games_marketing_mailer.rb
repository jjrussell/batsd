class GamesMarketingMailer < ActionMailer::Base
  include SendGrid

  self.delivery_method = :smtp
  self.smtp_settings = {
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :domain => 'tapjoy.com',
    :authentication => :plain,
    :user_name => RAILS_ENV == 'production' ?  'produser' : 'erictipton',
    :password => RAILS_ENV == 'production' ? 'prodpwd' : 'shufflethebits'
  }

  sendgrid_category :use_subject_lines
  sendgrid_enable :clicktrack, :opentrack

  def welcome_email(gamer, confirmation_link, gamer_device = nil, offer_data = {})
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Welcome to Tapjoy!"
    content_type 'text/html'
    android_device = gamer_device.device_type == 'android' rescue false
    body :confirmation_link => confirmation_link, :linked => gamer.gamer_devices.any?, :android_device => android_device, :offer_data => offer_data
  end

  def link_device(gamer, ios_link, android_link)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Tapjoy - Link Device"
    content_type 'text/html'
    body(:ios_link => ios_link, :android_link => android_link)
  end

  def invite(gamer_name, recipients_email, link)
    from "#{gamer_name} <noreply@tapjoy.com>"
    recipients recipients_email
    sendgrid_category 'Invite'
    subject "#{gamer_name} has invited you to join Tapjoy"
    content_type 'text/html'
    content = Invitation.invitation_message(gamer_name, link).split(/\n+/)
    body(:content => content)
  end
end
