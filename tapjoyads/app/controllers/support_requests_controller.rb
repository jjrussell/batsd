class SupportRequestsController < ApplicationController
  before_filter :setup
  
  layout 'iphone'
  
  def new
  end
  
  def create
    if params[:description].blank?
      render_new_with_error(I18n.t('text.support.missing_description'))
    elsif params[:email_address].blank? || params[:email_address] !~ Authlogic::Regex.email
      render_new_with_error(I18n.t('text.support.invalid_email'))
    else
      TapjoyMailer.deliver_support_request(params[:description], params[:email_address], @app, @currency, params[:udid],
        params[:publisher_user_id], params[:device_type], params[:language_code])
    end
  end

private

  def setup
    return unless verify_params([:currency_id, :app_id, :udid])
    @currency = Currency.find_in_cache(params[:currency_id])
    @app = App.find_in_cache(params[:app_id])
    return unless verify_records([@currency, @app])
  end
  
  def render_new_with_error(message)
    flash.now[:error] = message
    render(:action => :new) and return
  end

end