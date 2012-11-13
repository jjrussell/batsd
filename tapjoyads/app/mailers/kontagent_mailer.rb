class KontagentMailer < ActionMailer::Base
  default :from => 'Tapjoy <noreply@tapjoy.com>',
          :bcc  => 'email.receipts@tapjoy.com'
          # check with adam summner if the above is needed

  def approval(user)
    @username         = user.username
    mail :to => user.email, :subject => "Kontagent approval - Tapjoy"
  end
end
