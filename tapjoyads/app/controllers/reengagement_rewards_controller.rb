class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  layout 'mobile', :only => [ :show, :index ]

  def show
    verify_params([:id])
    @reengagement_offer = ReengagementOffer.find(params[:id])
    @app = App.find(@reengagement_offer.app_id) if @reengagement_offer
    @reengagement_offers = @app.reengagement_campaign if @app
    @currencies = @app.currencies if @reengagement_offers.try(:present?)
    @button_link = 'javascript: history.back()'

    if @currencies.try(:present?)
      render :index
    else
      render :nothing => true, :status => 204
    end
  end

  def index
    verify_params([:udid, :publisher_user_id, :app_id])
    @app = App.find_in_cache(params[:app_id])
    @currencies = Currency.find_all_in_cache_by_app_id(params[:app_id]) if @app
    @reengagement_offers = @app.reengagement_campaign_from_cache if @currencies.try(:present?)
    @reengagement_offer = ReengagementOffer.resolve(@app, @currencies, @reengagement_offers, params, geoip_data) if @reengagement_offers.try(:present?)
    @button_link = 'http://ok'

    render :nothing => true, :status => 204 unless @reengagement_offer && @app.reengagement_campaign_enabled?
  end

end
