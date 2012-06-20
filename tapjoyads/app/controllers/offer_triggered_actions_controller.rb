class OfferTriggeredActionsController < ApplicationController
  prepend_before_filter :decrypt_data_param
  before_filter :setup

  layout 'offer_instructions', :only => [ :fb_login, :fb_visit ]

  def fb_login
    include Facebooker2::Rails::Controller
    @redirect_url = "#{WEBSITE_URL}/gamer/create_account_for_offer?udid=#{params[:udid]}"
  end

  def fb_visit
    @generic_offer = GenericOffer.find_by_id params[:id]
    @fb_url = @generic_offer.fb_url
  end

  private

  def setup
    return unless verify_params([ :data, :id, :udid, :publisher_app_id ])

    @offer = Offer.find_in_cache params[:id]
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    return unless verify_records([ @currency, @offer ])

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
