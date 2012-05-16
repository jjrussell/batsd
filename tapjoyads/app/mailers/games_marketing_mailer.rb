class GamesMarketingMailer < ActionMailer::Base
  include SendGrid

  if Rails.env.production?
    self.delivery_method = :smtp
    self.smtp_settings = {
      :address => 'smtp.sendgrid.net',
      :port => 587,
      :domain => 'tapjoy.com',
      :authentication => :plain,
      :user_name => SENDGRID_USER,
      :password => SENDGRID_PASSWD
    }
  end

  sendgrid_category :use_subject_lines
  sendgrid_enable :clicktrack, :opentrack, :subscriptiontrack

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
    subject "Welcome to Tapjoy!"
    setup_emails(gamer, device_info)
    sendgrid_category "Welcome Email, #{@linked ? "Linked for Device Type #{@gamer_device.device_type}" : "Not Linked"}"
    @detailed_email = rand(2) == 1
    @linked &&= @detailed_email
    device_info[:content] = @detailed_email ? 'detailed' : 'confirm_only'
    device_info[:token] = gamer.confirmation_token
    sendgrid_category "Welcome Email, #{@linked ? "Linked for Device Type #{@gamer_device.device_type}" : "Not Linked"}, #{device_info[:content]}"
    @confirmation_link = "#{WEBSITE_URL}/confirm?data=#{ObjectEncryptor.encrypt(device_info)}"
  end

  def post_confirm_email(gamer, device_info = {})
    subject "Get Started with Tapjoy!"
    setup_emails(gamer, device_info)
    sendgrid_category "Secondary Welcome Email , #{@linked ? "Linked for Device Type #{@gamer_device.device_type}" : "Not Linked"}, #{device_info[:content]}"
    @detailed_email = true
    @template = 'welcome_email'
  end

  def invite(gamer_name, recipients_email, link)
    from "#{gamer_name} <noreply@tapjoy.com>"
    recipients recipients_email
    sendgrid_category 'Invite'
    subject "#{gamer_name} has invited you to join Tapjoy"
    content_type 'text/html'
    @gamer_name = gamer_name
    @link = link
  end

  private
  def setup_emails(gamer, device_info = {})
    from 'Tapjoy <noreply@tapjoy.com>'
    recipients gamer.email
    sendgrid_subscriptiontrack_text(:replace => "[unsubscribe_link]")
    @offer_data = {}
    device, @gamer_device, external_publisher = ExternalPublisher.most_recently_run_for_gamer(gamer)
    if external_publisher
      currency = external_publisher.currencies.first
      offerwall_url = external_publisher.get_offerwall_url(device, currency, device_info[:accept_language_str], device_info[:user_agent_str], nil, true)

      sess = Patron::Session.new
      response = sess.get(offerwall_url)
      raise "Error getting offerwall data" unless response.status == 200
      @offer_data[currency[:id]] = JSON.parse(response.body).merge(:external_publisher => external_publisher)
    end

    @gamer_device ||= gamer.gamer_devices.first
    selected_devices = device_info[:selected_devices] || []
    @linked = gamer_device.present?
    @android_device = @linked ? (gamer_device.device_type == 'android') : !selected_devices.include?('ios')
    @confirmation_link = "#{WEBSITE_URL}/confirm?token=#{CGI.escape(gamer.confirmation_token)}"

    device = Device.new(:key => @linked ? gamer_device.device_id : nil)
    @recommendations = device.recommendations(device_info.slice(:device_type, :geoip_data, :os_version))

    sendgrid_category "Welcome Email, #{@linked ? "Linked for Device Type #{gamer_device.device_type}" : "Not Linked"}"
    sendgrid_subscriptiontrack_text(:replace => "[unsubscribe_link]")
  end
end
