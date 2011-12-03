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

  # to send to litmus addresses in dev mode, just need to specify the [udid]@emailtests.com address as a recipient
  if RAILS_ENV == 'development'
    def instance_variable_set(ivar, val)
      return super(ivar, val) if ivar != '@recipients'

      recipients_arr = val.to_a
      recipients_arr.each do |recipient|
        if recipient =~ /.*@emailtests\.com/i
          recipients_arr += LITMUS_SPAM_ADDRESSES
          break
        end
      end

      super(ivar, recipients_arr)
    end
  end

  def welcome_email(gamer, gamer_device = nil, offer_data = {}, editors_picks = [])
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Welcome to Tapjoy!"

    gamer_device ||= gamer.gamer_devices.first
    linked = gamer_device.present?
    android_device = gamer_device.device_type == 'android' rescue false

    uri = URI.parse(WEBSITE_URL)
    confirmation_link = games_confirm_url(:protocol => uri.scheme, :host => uri.host, :token => gamer.confirmation_token)

    sendgrid_category "Welcome Email, #{linked ? "Linked for Device Type #{gamer_device.device_type}" : "Not Linked"}"
    body :confirmation_link => confirmation_link, :linked => linked, :android_device => android_device,
      :offer_data => offer_data, :editors_picks => editors_picks
  end

  def invite(gamer_name, recipients_email, link)
    from "#{gamer_name} <noreply@tapjoy.com>"
    recipients recipients_email
    sendgrid_category 'Invite'
    subject "#{gamer_name} has invited you to join Tapjoy"
    content_type 'text/html'
    content = Invitation.invitation_message(gamer_name).split(/\n+/)
    body(:content => content, :link => link)
  end
end
