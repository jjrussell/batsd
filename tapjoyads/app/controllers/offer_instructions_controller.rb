class OfferInstructionsController < ApplicationController
  prepend_before_filter :decrypt_data_param

  layout 'iphone', :only => :index

  def index
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
    })
  end

end
