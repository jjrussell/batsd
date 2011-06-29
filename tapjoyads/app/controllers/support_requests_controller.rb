class SupportRequestsController < ApplicationController
  before_filter :setup
  
  layout 'iphone'
  
  def new
    respond_to do |format|
      format.js do
        find_incomplete_offers
        render(:partial => 'select_offer', :layout => false)
      end
      format.html
    end
  end
  
  def create
    if params[:description].blank?
      render_new_with_error(I18n.t('text.support.missing_description'))
    elsif @offer.nil? && params[:offer_name].blank?
      render_new_with_error(I18n.t('text.support.missing_offer'))
    elsif params[:email_address].blank? || params[:email_address] !~ Authlogic::Regex.email
      render_new_with_error(I18n.t('text.support.invalid_email'))
    else
      TapjoyMailer.deliver_support_request(params[:description], params[:email_address], @app, @currency, params[:udid],
        params[:publisher_user_id], params[:device_type], params[:language_code], @offer || params[:offer_name])
    end
  end

private

  def setup
    return unless verify_params([:currency_id, :app_id, :udid])
    @currency = Currency.find_in_cache(params[:currency_id])
    @app = App.find_in_cache(params[:app_id])
    @offer = Offer.find_in_cache(params[:offer_id]) if params[:offer_id].present?
    return unless verify_records([@currency, @app])
  end
  
  def find_incomplete_offers
    conditions = "udid = '#{params[:udid]}' and currency_id = '#{params[:currency_id]}' and clicked_at > '#{2.weeks.ago.to_f}' and installed_at is null and manually_resolved_at is null"
    advertiser_offer_ids = []
    Click.select_all(:conditions => conditions).sort_by { |click| -click.clicked_at.to_f }.each do |click|
      advertiser_offer_ids << click.advertiser_app_id unless advertiser_offer_ids.include?(click.advertiser_app_id)
      break if advertiser_offer_ids.length == 10
    end
    @incomplete_offers = advertiser_offer_ids.collect { |offer_id| Offer.find_in_cache(offer_id) }
  end
  
  def render_new_with_error(message)
    find_incomplete_offers
    flash.now[:error] = message
    render(:action => :new) and return
  end

end