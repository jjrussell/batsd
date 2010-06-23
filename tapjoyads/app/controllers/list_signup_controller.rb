class ListSignupController < ApplicationController
  include GeoipHelper
  include SqsHelper
  include DownloadContent
  
  layout 'iphone'
  
  def index
    return unless verify_params([:udid, :publisher_app_id, :advertiser_app_id], {:allow_empty => false})
    
    @currency = Currency.find_in_cache_by_app_id(params[:publisher_app_id])
    @offer = Offer.find_in_cache(params[:advertiser_app_id])
    @publisher_app = SdbApp.new(:key => params[:publisher_app_id])
    @advertiser_app = SdbApp.new(:key => params[:advertiser_app_id])
  end
  
  def signup
    if params[:email_address] =~ /.+@.+/
      geoip_data = get_geoip_data(params, request)
      
      signup = EmailSignup.new
      signup.udid = params[:udid]
      signup.publisher_app_id = params[:publisher_app_id]
      signup.advertiser_app_id = params[:advertiser_app_id]
      signup.postal_code = geoip_data[:postal_code]
      signup.city = geoip_data[:city]
      signup.sent_date = Time.now
      
      signup.save
      
      @currency = Currency.find_in_cache_by_app_id(params[:publisher_app_id])
      @offer = Offer.find_in_cache(params[:advertiser_app_id])
      @publisher_app = App.find_in_cache(params[:publisher_app_id])
      
      # Send the emails via 4info.
      key = Digest::MD5.hexdigest("#{params[:email_address]}xFBysLNwaCRhGYKGXkpHjzWbVehBhE")
      
      reward_text = CGI::escape(@currency.get_reward_amount(@offer, nil).to_s + ' ' +
          @publisher_app.name + ' ' + @currency.name)
      
      url = 'http://www.4infoalerts.com/wap/tapjoy/post_email_address' +
          "?campaignId=#{@offer.third_party_data}" +
          "&id=#{signup.key}" +
          "&email=#{CGI::escape(params[:email_address])}" +
          "&reward=#{reward_text}" +
          "&udid=#{signup.udid}" +
          "&key=#{key}"
      
      download_with_retry(url, {:timeout => 5})
    else
      flash[:error] = "Invalid email address."
      flash[:email_address] = params[:email_address]
      redirect_to "/list_signup?udid=#{params[:udid]}&publisher_app_id=#{params[:publisher_app_id]}&advertiser_app_id=#{params[:advertiser_app_id]}"
    end
  end
  
  def confirm
    unless do_confirmation
      render :text => 'Unknown confirmation code'
    end
  end
  
  def confirm_api
    @success = do_confirmation
    render :template => 'layouts/tcro', :layout => false
  end
  
  private
  
  def do_confirmation
    email_signup_key = params[:code] || params[:id]
    
    @signup = EmailSignup.new(:key => email_signup_key)
    if @signup.is_new
      return false
    else
      @currency = Currency.find_in_cache_by_app_id(@signup.publisher_app_id)
      @publisher_app = App.find_in_cache(@signup.publisher_app_id)

      @signup.confirmed = Time.now
      @signup.save
      
      device_app_list = DeviceAppList.new(:key => @signup.udid)
      device_app_list.set_app_ran(@signup.advertiser_app_id)
      device_app_list.save
      
      message = {:udid => @signup.udid, :app_id => @signup.advertiser_app_id, 
          :install_date => Time.now.utc.to_f.to_s}.to_json
      send_to_sqs(QueueNames::CONVERSION_TRACKING, message)
      
      return true
    end
  end
  
end