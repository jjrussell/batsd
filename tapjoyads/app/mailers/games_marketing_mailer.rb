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

  def invite(gamer_name, recipients_email, link)
    from "#{gamer_name} <noreply@tapjoy.com>"
    recipients recipients_email
    sendgrid_category 'Invite'
    subject "#{gamer_name} has invited you to join Tapjoy"
    content_type 'text/html'
    @gamer_name = gamer_name
    @link = link
  end
end
