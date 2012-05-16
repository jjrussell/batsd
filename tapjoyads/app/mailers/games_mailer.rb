class GamesMailer < ActionMailer::Base
  default :from => 'Tapjoy <noreply@tapjoy.com>'

  def feedback(gamer, content, user_agent, device_id)
    @content = content
    @email = gamer.email
    @udid = device_id
    @user_agent = user_agent
    mail :to => "customerservice@tapjoy.com", :reply_to => gamer.email, :subject => "User Feedback - Tapjoy"
  end

  def report_bug(gamer, content, user_agent, device_id)
    @content = content
    @email = gamer.email
    @udid = device_id
    @user_agent = user_agent
    mail :to => "mobilehelp@tapjoy.com", :subject => "Bug Report - Tapjoy", :reply_to => gamer.email
  end

  def contact_support(gamer, gamer_device, content, user_agent, language_code, click, support_request)
    @content         = content
    @gamer           = gamer
    @gamer_device    = gamer_device
    @user_agent      = user_agent
    @language_code   = language_code
    @click           = click
    @support_request = support_request
    subject = click.present? ? "TJM User Support - #{click.offer.name}" : "TJM User Support"
    mail :to => "mobilehelp@tapjoy.com", :reply_to => gamer.email, :subject => subject
  end

  def password_reset(gamer, reset_link)
    @reset_link = reset_link
    mail :to => gamer.email, :subject => "Password Reset Request - Tapjoy"
  end

  def link_device(gamer, ios_link, android_link)
    @ios_link = ios_link
    @android_link = android_link
    mail :to => gamer.email, :subject => "Tapjoy - Link Device"
  end

  def delete_gamer(gamer)
    @name = gamer.get_gamer_name
    mail :to => gamer.email, :subject => "Tapjoy - Delete Account Confirmation"
  end
end
