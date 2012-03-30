class GamesMailer < ActionMailer::Base
  default :from => 'Tapjoy <noreply@tapjoy.com>'

  def feedback(gamer, content, user_agent, device_id)
    reply_to gamer.email
    recipients "customerservice@tapjoy.com"
    subject "User Feedback - Tapjoy"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end

  def report_bug(gamer, content, user_agent, device_id)
    reply_to gamer.email
    recipients "mobilehelp@tapjoy.com"
    subject "Bug Report - Tapjoy"
    content_type 'text/html'
    body(:content => content, :email => gamer.email, :udid => device_id, :user_agent => user_agent)
  end

  def contact_support(gamer, device, content, user_agent, language_code, click, support_request)
    from 'Tapjoy <noreply@tapjoy.com>'
    reply_to gamer.email
    #recipients "mobilehelp@tapjoy.com"
    recipients "brian.stebar@tapjoy.com"
    subject click.present? ? "Tapjoy User Support - #{click.offer.name}" : "Tapjoy User Support"
    content_type 'text/html'
    body(:content         => content,
         :gamer           => gamer,
         :device          => device,
         :user_agent      => user_agent,
         :language_code   => language_code,
         :click           => click,
         :support_request => support_request)
  end

  def password_reset(gamer, reset_link)
    recipients gamer.email
    subject "Password Reset Request - Tapjoy"
    content_type 'text/html'
    body :reset_link => reset_link
  end

  def link_device(gamer, ios_link, android_link)
    recipients gamer.email
    subject "Tapjoy - Link Device"
    content_type 'text/html'
    body(:ios_link => ios_link, :android_link => android_link)
  end

  def delete_gamer(gamer)
    @name = gamer.get_gamer_name
    mail(:to => gamer.email, :subject => "Tapjoy - Delete Account Confirmation")
  end
end
