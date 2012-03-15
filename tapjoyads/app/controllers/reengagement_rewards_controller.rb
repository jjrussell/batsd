class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  layout 'mobile', :only => [ :show, :index ]

  def show
    verify_params([:id])
    @reengagement_offer = ReengagementOffer.find(params[:id])
    @app = App.find(@reengagement_offer.app_id) if @reengagement_offer
    @reengagement_offers = @app.reengagement_campaign if @app
    @button_link = 'javascript: history.back()'

    if @reengagement_offers.try(:present?)
      render :index
    else
      render :nothing => true, :status => 204
    end
  end

  def index
    verify_params([:udid, :timestamp, :publisher_user_id, :app_id])
    @app = App.find_in_cache(params[:app_id])
    currencies = Currency.find_all_in_cache_by_app_id(params[:app_id]) if @app
    @reengagement_offer = ReengagementOffer.resolve(@app, currencies, params, geoip_data) if currencies
    @reengagement_offers = @app.reengagement_campaign_from_cache if @reengagement_offer
    @button_link = 'http://ok'

    render :nothing => true, :status => 204 and return unless @reengagement_offers && @app.reengagement_campaign_enabled?
  end

end
