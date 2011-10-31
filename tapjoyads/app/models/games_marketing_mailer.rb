class GamesMarketingMailer < ActionMailer::Base
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

  def invite(gamer_name, recipients_email, link)
    from "#{gamer_name} <noreply@tapjoy.com>"
    recipients recipients_email
    subject "#{gamer_name} has invited you to join Tapjoy"
    content_type 'text/html'
    content = Invitation.invitation_message(gamer_name, link).split(/\n+/)
    body(:content => content)
  end
end
