class EmailOfferController < ApplicationController

  layout 'iphone'

  def index
    return unless verify_params([ :udid, :click_key ])
    read_click
  end

  def create
    return unless verify_params([ :udid, :click_key ])
    if params[:email_address].blank? || params[:email_address] !~ Authlogic::Regex.email
      render_index_with_error('Please enter a real email address.')
    elsif params[:agreed_to_privacy].blank?
      render_index_with_error('Please indicate that you have accepted the privacy policy.')
    else
      email_address = EmailAddress.new(:key => params[:click_key])
      email_address.email_address = params[:email_address]
      email_address.udid = params[:udid]
      email_address.save
      TapjoyMailer.deliver_email_offer_confirmation(params[:email_address], params[:click_key])
    end
  end

  def confirm
    return unless verify_params([ :click_key ])
    read_click
    response = Downloader.get("#{API_URL}/offer_completed?click_key=#{params[:click_key]}", { :return_response => true, :timeout => 30 })
    if response.status == 200
      email_address = EmailAddress.new(:key => params[:click_key])
      email_address.confirmed_at = Time.zone.now
      email_address.save
      @confirm_text = "Your email address has been verified! You will receive your #{@currency.name} in a few moments."
    else
      @confirm_text = 'Your email address could not be verified. Please trying clicking the link in your email again.'
    end
  end

private

  def read_click
    @click = Click.find(params[:click_key], :consistent => true)
    @currency = Currency.find_in_cache(@click.currency_id)
    return unless verify_records([ @currency ])
  end

  def render_index_with_error(message)
    read_click
    flash.now[:error] = message
    render(:action => :index) and return
  end

end
