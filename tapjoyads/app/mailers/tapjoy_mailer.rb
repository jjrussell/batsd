class TapjoyMailer < ActionMailer::Base
  default :from => 'Tapjoy <noreply@tapjoy.com>',
          :bcc  => 'email.receipts@tapjoy.com'

  def newrelic_alert(error)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients "dev@tapjoy.com"
    subject "NewRelic Error: #{error.class}"
    body(:error => error)
  end

  def alert(message, rows)
    from 'Tapjoy <noc@tapjoy.com>'
    recipients [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ]
    subject "[ALERT] #{message}"
    body :rows => rows
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
    recipient_emails = partner.account_managers.map(&:email).tap do |emails|
      sales_rep_email = partner.sales_rep.try(:email)
      emails << partner.sales_rep.email unless sales_rep_email.blank? || emails.include?(sales_rep_email)
      emails.delete('oso@tapjoy.com')
      emails << 'accountmanagers@tapjoy.com' if emails.empty?
    end.join(', ')

    from 'Tapjoy <noreply@tapjoy.com>'
    reply_to recipient_emails
    recipients recipient_emails
    cc 'dev@tapjoy.com'
    subject "Low Conversion Rate Warning! - #{offer.name_with_suffix_and_platform}"
    body(:offer => offer, :stats => stats)
  end

  def suspicious_gamer_alert(gamer_id, gamer_email, behavior_type, behavior_result)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients 'dev@tapjoy.com'
    subject "Suspicious Gamer Behavior"
    content_type 'text/html'
    body(:gamer_id => gamer_id, :gamer_email => gamer_email, :behavior_type => behavior_type, :behavior_result => behavior_result)
  end

  def password_reset(user_email, reset_link, location, timestamp)
    from 'Tapjoy Support <support@tapjoy.com>'
    recipients user_email
    subject "Password Reset - Tapjoy.com"
    content_type 'text/html'
    body(:reset_link => reset_link, :location => location, :timestamp => timestamp)
  end

  def new_secondary_account(user_email, reset_link)
    @reset_link = reset_link
    mail :to => user_email, :from => 'Tapjoy Support <support@tapjoy.com>', :subject => "New Account Created - Tapjoy.com"
  end

  def whitepaper_request(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients "sunny.cha@tapjoy.com, raghu.nayani@tapjoy.com"
    info[:name] = [info[:first_name], info[:last_name]].join(' ').strip || info[:email]
    content_type 'text/html'
    subject_text = "Whitepaper request from #{info[:name]}"
    subject_text += " at #{info[:company]}" if info[:company].present?
    subject subject_text
    body(:info => info)
  end

  def androidfund_application(info)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients "marketing@tapjoy.com, publishing@tapjoy.com"
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
    cc 'accountspayable@tapjoy.com'
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

  def support_request(description, email_address, app, currency, device, publisher_user_id, device_type, language_code, user_agent, offer, support_request, click)
    from 'Online Support Request <noreply@tapjoy.com>'
    reply_to email_address
    recipients 'mobilehelp@tapjoy.com'
    content_type 'text/html'
    subject "Missing Currency - #{offer.name}"
    body( :description        => description,
          :app                => app,
          :partner_name       => app.partner_name,
          :partner_url        => app.partner_dashboard_partner_url,
          :currency           => currency,
          :device             => device,
          :publisher_user_id  => publisher_user_id,
          :device_type        => device_type,
          :email_address      => email_address,
          :language_code      => language_code,
          :user_agent         => user_agent,
          :offer              => offer,
          :support_request    => support_request,
          :click              => click)
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
    recipients 'fianancepartnernamechange@tapjoy.com'
    content_type 'text/html'
    subject 'Partner Name Change Notification'
    body(:partner => partner, :name_was => name_was, :acct_mgr_email => acct_mgr_email, :partner_link => partner_link)
  end

  def partner_signup(email_address)
    mail :to => email_address, :subject => 'Thanks for signing up with Tapjoy!'
  end

  def resolve_support_requests(user_email, mass_resolve_results, upload_time)
    upload_time_stamp = upload_time.to_s(:pub_ampm)
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients user_email
    cc 'customerservice@tapjoy.com'
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
