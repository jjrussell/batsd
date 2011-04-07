class TapjoyMailer < ActionMailer::Base
  
  def newrelic_alert(error)
    from "admin@tapjoy.com"
    recipients "dev@tapjoy.com"
    subject "NewRelic Error: #{error.inspect}"
    body(:error => error)
  end
  
  def sms_sent(phone, message)
    from "admin@tapjoy.com"
    recipients "dev@tapjoy.com"
    subject "An SMS has been sent"
    body :text => "An sms has been sent to #{phone}, with the message: #{message}"
  end
  
  def email_signup(to_email, confirm_code, currency_name, publisher_app_name, amount)
    from "noreply@tapjoy.com"
    recipients to_email
    subject "Confirmation email - get #{amount} #{publisher_app_name} #{currency_name}"
    content_type 'text/html'
    url = "#{API_URL}/list_signup/confirm?code=#{confirm_code}"
    body :url => url, :currency_name => currency_name, :publisher_app_name => publisher_app_name, :amount => amount
  end
  
  def low_conversion_rate_warning(error, params)
    from "admin@tapjoy.com"
    partner = Partner.find_by_id(params[:partner_id], :include => [ :users ])
    account_managers = partner.account_managers.map(&:email)
    account_managers.delete "oso@tapjoy.com"
    account_managers += [ 'marketing@tapjoy.com', 'dev@tapjoy.com' ]
    account_managers = account_managers.join(', ')
    reply_to account_managers
    recipients account_managers
    subject "Low Conversion Rate Warning!"
    body(:error => error)
  end
  
  def balance_alert(offer, potential_spend)
    from "support@tapjoy.com"
    reply_to "marketing@tapjoy.com, dev@tapjoy.com"
    recipients "marketing@tapjoy.com, dev@tapjoy.com"
    subject "Balance is getting low for #{offer.name}"
    body(:offer => offer, :potential_spend => potential_spend)
  end
  
  def password_reset(user_email, reset_link)
    from "support@tapjoy.com"
    recipients user_email
    subject "Password Reset - Tapjoy.com"
    content_type 'text/html'
    body(:reset_link => reset_link)
  end
  
  def new_secondary_account(user_email, reset_link)
    from "support@tapjoy.com"
    recipients user_email
    subject "New Account Created - Tapjoy.com"
    content_type 'text/html'
    body(:reset_link => reset_link)
  end

  def contact_us(info)
    from 'support@tapjoy.com'
    if Rails.env == 'development'
      recipients "dev@tapjoy.com"
    else
      recipients "support+contactus@tapjoy.com"
    end
    content_type 'text/html'
    subject "Website form inquiry from #{info[:first]} #{info[:last]} at #{info[:company]}"
    body(:info => info)
  end

  def publisher_application(info)
    from 'support@tapjoy.com'
    if Rails.env == 'development'
      recipients "dev@tapjoy.com"
    else
      recipients "publisher@tapjoy.com"
    end
    content_type 'text/html'
    subject "Publisher form inquiry from #{info[:first]} #{info[:last]} at #{info[:company]}"
    body(:info => info)
  end

  def campaign_status(email_recipients, low_balance, account_balance, account_manager_email, offers_not_meeting_budget, offers_needing_higher_bids, premier, premier_discount)
    from 'support@tapjoy.com'
    recipients email_recipients
    subject 'Tapjoy Campaign Status'
    content_type 'text/html'
    account_manager_email = nil if account_manager_email == 'oso@tapjoy.com'
    body(:low_balance => low_balance, :account_balance => account_balance, :account_manager_email => account_manager_email, 
      :offers_not_meeting_budget => offers_not_meeting_budget, :offers_needing_higher_bids => offers_needing_higher_bids, :premier => premier, :premier_discount => premier_discount)
  end

  def payout_info_reminder(email_recipients, earnings)
    from 'support@tapjoy.com'
    cc 'hwanjoon@tapjoy.com'#'accountspayable@tapjoy.com'
    recipients email_recipients
    subject 'Payment Information Needed'
    content_type 'text/html'
    body(:earnings => earnings)
  end
end
