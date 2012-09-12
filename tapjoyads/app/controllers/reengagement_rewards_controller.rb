class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  layout 'mobile'

  OK_BUTTON_URL = "http://ok"

  def index
    verify_params([:udid, :publisher_user_id, :app_id])
    @app = App.find_in_cache(params[:app_id])
    @currencies = Currency.find_all_in_cache_by_app_id(params[:app_id]) if @app.try(:reengagement_campaign_enabled?)
    @reengagement_offers = ReengagementOffer.find_all_in_cache_by_app_id(params[:app_id]) if @currencies.present?
    @reengagement_offer = ReengagementOffer.resolve(@app, @currencies, @reengagement_offers, params, geoip_data) if @reengagement_offers.present?
    render :nothing => true, :status => 204 and return unless @reengagement_offer
  end
end
