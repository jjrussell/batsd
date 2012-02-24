class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  layout 'mobile', :only => 'index'

  def index
    if params[:id]
      # used for previews
      @reengagement_offer = ReengagementOffer.find(params[:id])
      @app = App.find(@reengagement_offer.app_id) if @reengagement_offer.present?
      @currencies = @app.currencies
      @reengagement_offers = @app.reengagement_campaign     # so previews work without the campaign needing to be enabled
    else
      # used by client device
      verify_params([:udid, :timestamp, :publisher_user_id, :app_id])

      @app = App.find_in_cache(params[:app_id])
      @currencies = Currency.find_all_in_cache_by_app_id(params[:app_id])

      render :nothing => true, :status => 204 and return unless @app

      @reengagement_offer = ReengagementOffer.resolve(@app, @currencies, params, geoip_data)
      @reengagement_offers = @app.reengagement_campaign_from_cache
    end

    render :nothing => true, :status => 204 and return unless @reengagement_offer
    @button_link = button_link
    render :nothing => true, :status => 204 and return unless @reengagement_offers.present?
  end

  private

  def button_link
    user_agent = request.env['HTTP_USER_AGENT'].downcase
    user_agent =~ /iphone|android|ipod|ipad/ ? 'http://ok' : ''
  end

end
