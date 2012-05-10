class OfferTriggeredActionsController < ApplicationController
  include Facebooker2::Rails::Controller
  prepend_before_filter :decrypt_data_param
  before_filter :setup

  layout 'facebook', :only => :facebook_login

  def facebook_login
    @redirect_url = "#{WEBSITE_URL}/games/gamer/create_account_for_offer?udid=#{params[:udid]}"
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
