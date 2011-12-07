class GamesMarketingMailer < ActionMailer::Base
  include SendGrid

  self.delivery_method = :smtp
  self.smtp_settings = {
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :domain => 'tapjoy.com',
    :authentication => :plain,
    :user_name => SEND_GRID_USER,
    :password => SEND_GRID_PASSWD
  }

  sendgrid_category :use_subject_lines
  sendgrid_enable :clicktrack, :opentrack

  # to send to litmus addresses in dev mode, just need to specify the [udid]@emailtests.com address as a recipient
  if Rails.env.development?
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

  def welcome_email(gamer, device_info = {})
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    subject "Welcome to Tapjoy!"

    offer_data = {}
    device, gamer_device, external_publisher = ExternalPublisher.most_recently_run_for_gamer(gamer)
    if external_publisher
      currency = external_publisher.currencies.first
      offerwall_url = external_publisher.get_offerwall_url(device, currency, device_info[:accept_language], device_info[:user_agent])

      sess = Patron::Session.new
      response = sess.get(offerwall_url)
      raise "Error getting offerwall data" unless response.status == 200
      offer_data[currency[:id]] = JSON.parse(response.body).merge(:external_publisher => external_publisher)
    end

    editors_picks = offer_data.any? ? [] : EditorsPick.cached_active(device_info[:is_android] ? 'android' : 'ios')

    gamer_device ||= gamer.gamer_devices.first
    linked = gamer_device.present?
    android_device = linked ? (gamer_device.device_type == 'android') : false

    protocol, host = WEBSITE_URL.split("://")
    confirmation_link = url_for(:protocol => protocol, :host => host, :controller => "confirm", :token => gamer.confirmation_token)

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
