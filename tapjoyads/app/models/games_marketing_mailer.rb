class GamesMarketingMailer < ActionMailer::Base
  include SendGrid

  self.delivery_method = :smtp
  self.smtp_settings = {
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :domain => 'tapjoy.com',
    :authentication => :plain,
    :user_name => RAILS_ENV == 'production' ? 'tapjoyprod' : 'tapjoydev',
    :password => RAILS_ENV == 'production' ? 'b4%6GbMv' : 'emailthebits'
  }

  sendgrid_category :use_subject_lines
  sendgrid_enable :clicktrack, :opentrack

  def welcome_email(gamer, confirmation_link, gamer_device = nil, offer_data = {}, editors_picks = [])
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Welcome to Tapjoy!"

    gamer_device ||= gamer.gamer_devices.first
    linked = gamer_device.present?
    android_device = gamer_device.device_type == 'android' rescue false
    sendgrid_category "Welcome Email, #{linked ? "Linked for Device Type #{gamer_device.device_type}" : "Not Linked"}"

    body :confirmation_link => confirmation_link, :linked => linked, :android_device => android_device,
      :offer_data => offer_data, :editors_picks => editors_picks
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
