class EmailOfferController < ApplicationController
  
  layout 'iphone'
  
  def index
    return unless verify_params([ :udid, :click_key ])
    @click = Click.find(params[:click_key])
    @currency = Currency.find_in_cache(@click.currency_id)
  end
  
  def create
    if params[:email_address].blank? || params[:email_address] !~ Authlogic::Regex.email
      render_index_with_message('Please enter a real email address.')
    elsif params[:agreed_to_privacy].blank?
      render_index_with_message('Please indicate that you have accepted the privacy policy.')
    end
    email_address = EmailAddress.new(:key => params[:click_key])
    email_address.email_address = params[:email_address]
    email_address.udid = params[:udid]
    email_address.save
    TapjoyMailer.deliver_email_offer_confirmation(params[:email_address], params[:click_key])
  end
  
  def confirm
    return unless verify_params([ :click_key ])
    response = Downloader.get("#{API_URL}/offer_completed?click_key=#{params[:click_key]}", { :return_response => true, :timeout => 30 })
    if response.status == 200
      email_address = EmailAddress.new(:key => params[:click_key])
      email_address.confirmed_at = Time.zone.now
      email_address.save
      @confirm_text = 'Your email address has been verified!'
    else
      @confirm_text = 'Your email address could not be verified. Please trying clicking the link in your email again.'
    end
  end
  
private

  def render_index_with_error(message)
    @click = Click.find(params[:click_key])
    @currency = Currency.find_in_cache(@click.currency_id)
    flash.now[:error] = message
    render(:action => :index) and return
  end
  
end
