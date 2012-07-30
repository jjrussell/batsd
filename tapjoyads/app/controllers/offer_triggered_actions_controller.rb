class OfferTriggeredActionsController < ApplicationController
  prepend_before_filter :decrypt_data_param
  before_filter :setup

  layout 'offer_instructions', :only => [ :load_app, :fb_login, :fb_visit ]

  def load_app
    @protocol_handler_url = @offer.generic_offer_protocol_handler
  end

  def fb_login
    include Facebooker2::Rails::Controller
    @redirect_url = "#{WEBSITE_URL}/gamer/create_account_for_offer?udid=#{params[:udid]}"
  end

  def fb_visit
  end

  private

  def setup
    return unless verify_params([ :data, :id, :udid, :publisher_app_id ])

    @offer = Offer.find_in_cache params[:id]
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    return unless verify_records([ @currency, @offer ])
    @impression_tracking_url = @offer.impression_tracking_urls
    @click_tracking_url = @offer.click_tracking_urls
    @conversion_tracking_url = @offer.conversion_tracking_urls

    @complete_action_url = @offer.complete_action_url({
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => params[:click_key],
      :itunes_link_affiliate => params[:itunes_link_affiliate],
      :library_version       => params[:library_version],
      :os_version            => params[:os_version]
    })
  end

end
