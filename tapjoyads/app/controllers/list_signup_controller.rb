class ListSignupController < ApplicationController
  include GeoipHelper
  include SqsHelper
  
  layout 'iphone'
  
  def index
    @currency = Currency.new(:key => params[:publisher_app_id])
    @publisher_app = App.new(:key => params[:publisher_app_id])
    @advertiser_app = App.new(:key => params[:advertiser_app_id])
  end
  
  def signup
    if params[:email_address] =~ /.+@.+/
      geoip_data = get_geoip_data(params, request)
      
      signup = EmailSignup.new
      signup.udid = params[:udid]
      signup.publisher_app_id = params[:publisher_app_id]
      signup.advertiser_app_id = params[:advertiser_app_id]
      signup.email_address = params[:email_address]
      signup.postal_code = geoip_data[:postal_code]
      
      signup.save
      
      @currency = Currency.new(:key => params[:publisher_app_id])
      @publisher_app = App.new(:key => params[:publisher_app_id])
      @advertiser_app = App.new(:key => params[:advertiser_app_id])
      
      # If we wanted to be less prone to griefers here, we could confirm that the
      # udid hasn't filled out this offer yet. Also, check how many times we've sent
      # an email to a given address, and how many times an IP address has sent an email.
      # Not needed for the trial though.
      
      TapjoyMailer.deliver_email_signup(params[:email_address], signup.key, @currency.currency_name, @publisher_app.name, @currency.get_app_currency_reward(@advertiser_app))
    else
      flash[:error] = "Invalid email address."
      flash[:email_address] = params[:email_address]
      redirect_to :back
    end
  end
  
  def confirm
    @signup = EmailSignup.new(:key => params[:code])
    if @signup.is_new
      render :text => 'Unknown confirmation code'
    else
      @currency = Currency.new(:key => @signup.publisher_app_id)
      @publisher_app = App.new(:key => @signup.publisher_app_id)

      @signup.confirmed = Time.now
      @signup.save
      
      device_app_list = DeviceAppList.new(:key => @signup.udid)
      device_app_list.set_app_ran(@signup.advertiser_app_id)
      device_app_list.save
      
      message = {:udid => @signup.udid, :app_id => @signup.advertiser_app_id, 
          :install_date => Time.now.utc.to_f.to_s}.to_json
      send_to_sqs(QueueNames::CONVERSION_TRACKING, message)
    end
  end
  
end