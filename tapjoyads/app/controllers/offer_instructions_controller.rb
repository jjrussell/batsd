class OfferInstructionsController < ApplicationController
  prepend_before_filter :decrypt_data_param

  layout 'iphone'

  def index
    return unless verify_params([ :data, :id, :publisher_app_id, :udid ])
    @offer = Offer.find_in_cache(params[:id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    return unless verify_records([ @offer, @currency ])

    @device_type = params[:device_type]

    if @offer.item_type == 'ActionOffer' && (@action_app = App.find_in_cache(@offer.action_offer_app_id))
      params.delete(:data)
      params[:action_app_id] = @action_app.id
      params[:data] = ObjectEncryptor.encrypt(params)
    end

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

  def app_not_installed
    return unless verify_params([ :data, :id, :action_app_id ])
    @offer = Offer.find_in_cache(params[:id])
    @action_app = App.find_in_cache(params[:action_app_id])
    return unless verify_records([ @offer, @action_app ])
  end
end
