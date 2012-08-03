class Job::QueueSendWelcomeEmailsController < Job::SqsReaderController

  def initialize
    super QueueNames::SEND_WELCOME_EMAILS
    ##
    ## TODO: Consolidate all email queues for ET emails into one ET_EMAIL_QUEUE
    ##
  end

  private

  def on_message(message)
    ##
    ## TODO: Set up an ExactTarget status checking job to store whether or not ET is up.
    ##       Then modify this job to check the stored status before trying to send mail.
    ##
    device_info = Marshal.restore(Base64::decode64(message.body))

    gamer = Gamer.find(device_info.delete(:gamer_id))
    email_type = device_info.delete(:email_type) || 'welcome'
    # mail = GamesMarketingMailer.send("create_#{email_type}_email", gamer, device_info)
    # GamesMarketingMailer.deliver(mail) if EmailVerifier.check_recipients(mail)

    mailer = TransactionalMailer.new
    mailer.send("#{email_type}_email", gamer, device_info)

    ##
    ## TODO: Check response from mailer call
    ##

    # device_info =
    # {:os_version=>"2.3.6",
    #  :gamer_id=>"1f3caa41-9805-4925-a4be-42c06fbd3187",
    #  :accept_language_str=>"en-US",
    #  :device_type=>"android",
    #  :user_agent_str=>
    #   "Mozilla/5.0 (Linux; U; Android 2.3.6; en-us; SPH-D700 Build/GINGERBREAD) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
    #  :selected_devices=>"",
    #  :geoip_data=>
    #   {:user_country_code=>nil, :carrier_country_code=>nil, :primary_country=>nil}}

    # device_info =
    # {:os_version=>"5.1.1",
    #  :gamer_id=>"f49d6739-3389-446f-80c3-e98a3888e998",
    #  :accept_language_str=>"en-US,en;q=0.8",
    #  :device_type=>"ipad",
    #  :user_agent_str=>
    #   "Mozilla/5.0 (iPad; U; CPU OS 5_1_1 like Mac OS X; en-us) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3",
    #  :selected_devices=>"",
    #  :geoip_data=>
    #   {:user_country_code=>nil, :carrier_country_code=>nil, :primary_country=>nil}}
  end
end
