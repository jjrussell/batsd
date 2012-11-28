class SupportRequestsController < ApplicationController
  before_filter :lookup_device, :setup

  layout 'iphone'

  def new
    @show_topbar = library_version >= '9'
  end

  def create
    if @offer.nil?
      render_new_with_error(I18n.t('text.support.missing_offer'))
    elsif params[:description].blank?
      render_new_with_error(I18n.t('text.support.missing_description'))
    elsif params[:email_address].blank? || params[:email_address] !~ Authlogic::Regex.email
      render_new_with_error(I18n.t('text.support.invalid_email'))
    elsif duplicate_support_request?
      render_new_with_error(I18n.t('test.support.duplicate_support_request', :default => "You've already submitted a support request for this offer."))
    else
      support_request = SupportRequest.new
      support_request.fill_from_params(params, @app, @currency, @offer, request.env["HTTP_USER_AGENT"])
      support_request.save

      click = Click.new(:key => support_request.click_id)
      device = find_or_create_device

      TapjoyMailer.support_request(params[:description], params[:email_address], @app, @currency, device,
        params[:publisher_user_id], params[:device_type], params[:language_code], request.env["HTTP_USER_AGENT"], @offer,
        support_request, click).deliver
    end
  end

  def incomplete_offers
    find_incomplete_offers
    render(:partial => 'select_offer', :layout => false)
  end

private

  def setup
    return unless verify_params([:currency_id, :app_id, :tapjoy_device_id])
    @currency = Currency.find_in_cache(params[:currency_id])
    @app = App.find_in_cache(params[:app_id])
    @offer = Offer.find_in_cache(params[:offer_id]) if params[:offer_id].present?
    return unless verify_records([@currency, @app])
  end

  def find_incomplete_offers
    conditions = ["tapjoy_device_id = ? or udid = ? and currency_id = ? and clicked_at > ? and manually_resolved_at is null", params[:tapjoy_device_id], params[:udid], params[:currency_id], 30.days.ago.to_f]
    advertiser_offer_ids = []
    Click.select_all(:conditions => conditions).sort_by { |click| -click.clicked_at.to_f }.each do |click|
      advertiser_offer_ids << click.advertiser_app_id unless advertiser_offer_ids.include?(click.advertiser_app_id)
      break if advertiser_offer_ids.length == 20
    end
    @incomplete_offers = advertiser_offer_ids.collect { |offer_id| Offer.find_in_cache(offer_id) }.compact
  end

  def render_new_with_error(message)
    find_incomplete_offers
    flash.now[:error] = message
    render('new') and return
  end

  def duplicate_support_request?
    SupportRequest.find_support_request(params[:udid], params[:tapjoy_device_id], @offer.id).present?
  end
end
