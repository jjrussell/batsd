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

  def low_conversion_rate_warning(offer, stats)
    partner = Partner.find_by_id(offer.partner_id, :include => [ :users ])
    account_managers = partner.account_managers.map(&:email)
    account_managers.delete "oso@tapjoy.com"
    account_managers += [ 'accountmanagers@tapjoy.com', 'dev@tapjoy.com' ]
    account_managers = account_managers.join(', ')

    from "admin@tapjoy.com"
    reply_to account_managers
    recipients account_managers
    subject "Low Conversion Rate Warning! - #{offer.name_with_suffix_and_platform}"
    body(:offer => offer, :stats => stats)
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
    subject "Contact us from #{info[:name]}"
    body(:info => info)
  end

  def publisher_application(info)
    from 'support@tapjoy.com'
    if Rails.env == 'development'
      recipients "dev@tapjoy.com"
    else
      recipients "publishing@tapjoy.com"
    end
    content_type 'text/html'
    subject "Publisher form inquiry from #{info[:first]} #{info[:last]} at #{info[:company]}"
    body(:info => info)
  end
  
  def androidfund_application(info)
    from 'admin@tapjoy.com'
    if Rails.env == 'development'
      recipients "dev+androidfund@tapjoy.com"
    else
      recipients "marketing@tapjoy.com, publishing@tapjoy.com"
    end
    content_type 'text/html'
    subject "Publisher form inquiry from #{info[:first]} #{info[:last]} at #{info[:company]}"
    body(:info => info)
  end

  def campaign_status(email_recipients, partner, low_balance, account_balance, account_manager_email, offers_not_meeting_budget, offers_needing_higher_bids, premier, premier_discount)
    from 'support@tapjoy.com'
    recipients email_recipients
    subject "Tapjoy Campaign Status for #{partner.name || partner.contact_name}"
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
  
  def email_offer_confirmation(email_address, click_key)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients email_address
    subject 'Welcome to Tapjoy Games'
    content_type 'text/html'
    body(:click_key => click_key)
  end
  
  def support_request(description, email_address, app, currency, udid, publisher_user_id, device_type, language_code, offer)
    from 'Online Support Request <noreply@tapjoy.com>'
    reply_to email_address
    recipients 'mobilehelp@tapjoy.com'
    content_type 'text/html'
    subject 'Missing Currency'
    body(:description => description, :app => app, :currency => currency, :udid => udid, :publisher_user_id => publisher_user_id,
      :device_type => device_type, :email_address => email_address, :language_code => language_code, :offer => offer)
  end
  
  def approve_device(email_address, verification_key, block_link, reset_link)
    from 'noreply@tapjoy.com'
    recipients email_address
    content_type 'text/html'
    subject 'Approve Unknown Device'
    body(:verification_key => verification_key, :block_link => block_link, :reset_link => reset_link)
    from
  end
end
