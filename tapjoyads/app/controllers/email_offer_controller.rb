class EmailOfferController < ApplicationController
  
  layout 'iphone'
  
  def index
    return unless verify_params([ :udid, :click_key ])
  end
  
  def create
    if params[:email_address] !~ Authlogic::Regex.email
      render :text => 'That is not a real email address.'
      return
    end
    email_address = EmailAddress.new(:key => params[:click_key])
    email_address.email_address = params[:email_address]
    email_address.udid = params[:udid]
    email_address.save
    TapjoyMailer.deliver_email_offer_confirmation(email_address, click_key)
    render :text => 'Now click the link in the confirmation email.'
  end
  
  def confirm
    return unless verify_params([ :click_key ])
    response = Downloader.get("https://ws.tapjoyads.com/offer_completed?click_key=#{params[:click_key]}", { :return_response => true, :timeout => 30 })
    if response.status == 200
      email_address = EmailAddress.new(:key => params[:click_key])
      email_address.confirmed_at = Time.zone.now
      email_address.save
      render :text => 'Thanks!'
    else
      render :text => 'Something did not work right.'
    end
  end
  
end
