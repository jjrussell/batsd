class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
  end

  private

  def on_message(message)
    device_info = Marshal.restore(Base64::decode64(message.body))

    gamer = Gamer.find(device_info.delete(:gamer_id))
    # email_type = device_info.delete(:email_type) || 'welcome'
    # mail = GamesMarketingMailer.send("create_#{email_type}_email", gamer, device_info)
    # GamesMarketingMailer.deliver(mail) if EmailVerifier.check_recipients(mail)

    mailer = TransactionalMailer.new
    mailer.welcome_email(gamer, device_info)

    # device_info
    # => {:os_version=>nil,
    #  :gamer_id=>"acb59e3c-e832-4613-9450-7359b4fda120",
    #  :accept_language_str=>"en-US,en;q=0.8",
    #  :device_type=>nil,
    #  :user_agent_str=>
    #   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11",
    #  :selected_devices=>"ios",
    #  :geoip_data=>
    #   {:user_country_code=>nil, :carrier_country_code=>nil, :primary_country=>nil}}
    #
  end
end
