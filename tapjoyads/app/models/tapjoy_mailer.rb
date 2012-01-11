class TapjoyMailer < ActionMailer::Base

  def newrelic_alert(error)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients "dev@tapjoy.com"
    subject "NewRelic Error: #{error.class}"
    body(:error => error)
  end

  def sms_sent(phone, message)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients "dev@tapjoy.com"
    subject "An SMS has been sent"
    body :text => "An sms has been sent to #{phone}, with the message: #{message}"
  end

  def email_signup(to_email, confirm_code, currency_name, publisher_app_name, amount)
    from 'Tapjoy <noreply@tapjoy.com>'
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

    from 'Tapjoy <noreply@tapjoy.com>'
    reply_to account_managers
    recipients account_managers
    subject "Low Conversion Rate Warning! - #{offer.name_with_suffix_and_platform}"
    body(:offer => offer, :stats => stats)
  end

  def password_reset(user_email, reset_link)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients user_email
    subject "Password Reset - Tapjoy.com"
    content_type 'text/html'
    body(:reset_link => reset_link)
  end

  def new_secondary_account(user_email, reset_link)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients user_email
    subject "New Account Created - Tapjoy.com"
    content_type 'text/html'
    body(:reset_link => reset_link)
  end

  def contact_us(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    if !Rails.env.production?
      recipients "dev@tapjoy.com"
    else
      recipients "support+contactus@tapjoy.com"
    end
    content_type 'text/html'
    subject "Contact us from #{info[:name]}"
    body(:info => info)
  end

  def publisher_application(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    if !Rails.env.production?
      recipients "dev@tapjoy.com"
    else
      recipients "publishing@tapjoy.com"
    end
    content_type 'text/html'
    subject "Publisher form inquiry from #{info[:first]} #{info[:last]} at #{info[:company]}"
    body(:info => info)
  end

  def whitepaper_request(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    if !Rails.env.production?
      recipients "dev@tapjoy.com"
    else
      recipients "sunny.cha@tapjoy.com, raghu.nayani@tapjoy.com"
    end
    info[:name] = [info[:first_name], info[:last_name]].join(' ').strip || info[:email]
    content_type 'text/html'
    subject_text = "Whitepaper request from #{info[:name]}"
    subject_text += " at #{info[:company]}" if info[:company].present?
    subject subject_text
    body(:info => info)
  end

  def advertiser_application(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    if Rails.env.production?
      recipients "insidesales@tapjoy.com"
    else
      recipients "dev@tapjoy.com"
    end
    content_type 'text/html'
    subject "Advertiser inquiry from #{info[:name]} at #{info[:company]}"
    body(:info => info)
  end

  def androidfund_application(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    if !Rails.env.production?
      recipients "dev+androidfund@tapjoy.com"
    else
      recipients "marketing@tapjoy.com, publishing@tapjoy.com"
    end
    content_type 'text/html'
    subject "Publisher form inquiry from #{info[:first]} #{info[:last]} at #{info[:company]}"
    body(:info => info)
  end

  def campaign_status(email_recipients, partner, low_balance, account_balance, account_manager_email, offers_not_meeting_budget, offers_needing_higher_bids, premier, premier_discount)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients email_recipients
    subject "Tapjoy Campaign Status for #{partner.name || partner.contact_name}"
    content_type 'text/html'
    account_manager_email = nil if account_manager_email == 'oso@tapjoy.com'
    body(:low_balance => low_balance, :account_balance => account_balance, :account_manager_email => account_manager_email,
      :offers_not_meeting_budget => offers_not_meeting_budget, :offers_needing_higher_bids => offers_needing_higher_bids, :premier => premier, :premier_discount => premier_discount)
  end

  def payout_info_reminder(email_recipients, earnings)
    from 'Tapjoy Support <support@tapjoy.com>'
    cc 'hwanjoon@tapjoy.com'#'accountspayable@tapjoy.com'
    recipients email_recipients
    subject 'Payment Information Needed'
    content_type 'text/html'
    body(:earnings => earnings)
  end

  def email_offer_confirmation(email_address, click_key)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients email_address
    subject 'Welcome to Tapjoy'
    content_type 'text/html'
    body(:click_key => click_key)
  end

  def support_request(description, email_address, app, currency, udid, publisher_user_id, device_type, language_code, offer, support_request, click_id)
    from 'Online Support Request <noreply@tapjoy.com>'
    reply_to email_address
    recipients 'mobilehelp@tapjoy.com'
    content_type 'text/html'
    subject 'Missing Currency'
    body(:description => description, :app => app, :currency => currency, :udid => udid, :publisher_user_id => publisher_user_id,
      :device_type => device_type, :email_address => email_address, :language_code => language_code, :offer => offer,
      :support_request => support_request, :click_id => click_id)
  end

  def approve_device(email_address, verification_link, password_reset_link, location, timestamp)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients email_address
    content_type 'text/html'
    subject 'Approve Unknown Computer or Device'
    body(:verification_link => verification_link, :password_reset_link => password_reset_link, :location => location, :timestamp => timestamp)
  end

  def partner_name_change_notification(partner, name_was, acct_mgr_email, partner_link)
    from 'Tapjoy <noreply@tapjoy.com>'
    if Rails.env.production?
      recipients 'accounting@tapjoy.com'
    else
      recipients 'dev@tapjoy.com'
    end
    content_type 'text/html'
    subject 'Partner Name Change Notification'
    body(:partner => partner, :name_was => name_was, :acct_mgr_email => acct_mgr_email, :partner_link => partner_link)
  end

  def partner_signup(email_address)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients email_address
    content_type 'text/html'
    subject 'Thanks for signing up with Tapjoy!'
  end

  def resolve_support_requests(user_email, mass_resolve_results, upload_time)
    upload_time_stamp = upload_time.to_s(:pub_ampm)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients user_email
    if Rails.env.production?
      cc 'customerservice@tapjoy.com'
    end
    content_type 'text/html'
    subject "Support Request for Mass Resolution initiated on #{upload_time_stamp}"
    body(:mass_resolve_results => mass_resolve_results, :upload_time_stamp => upload_time_stamp)
  end

  def approve_offer_creative(email_address, offer, app, approval_link)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients email_address
    content_type 'text/html'
    subject "New Custom Creative requires approval"
    body(:offer => offer, :app => app, :approval_url => approval_link)
  end

  def offer_creative_approved(email_address, offer, size, offer_link)
    offer_creative_updated(:approved, email_address, offer, size, offer_link)
  end

  def offer_creative_rejected(email_address, offer, size, offer_link)
    offer_creative_updated(:rejected, email_address, offer, size, offer_link)
  end

  private
  def offer_creative_updated(status, email_address, offer, size, offer_link)
    from('Tapjoy <noreply@tapjoy.com>')
    recipients(email_address)
    content_type('text/html')
    subject("Custom creative has been #{status}!")
    body(:offer => offer, :size => size, :offer_url => offer_link)
    template("offer_creative_#{status}")
  end
end
