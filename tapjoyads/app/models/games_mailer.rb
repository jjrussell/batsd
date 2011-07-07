class GamesMailer < ActionMailer::Base
  
  def gamer_confirmation(gamer, confirmation_link)
    from "noreply@tapjoygames.com"
    recipients gamer.email
    subject "Account Confirmation - Tapjoy Games"
    content_type 'text/html'
    body :confirmation_link => confirmation_link
  end
  
  def password_reset(gamer, reset_link)
    from "support@tapjoygames.com"
    recipients gamer.email
    subject "Password Reset Request - Tapjoy Games"
    content_type 'text/html'
    body :reset_link => reset_link
  end
  
end
