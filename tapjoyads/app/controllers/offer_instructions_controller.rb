class OfferInstructionsController < ApplicationController
  prepend_before_filter :setup
  
  layout 'iphone', :only => :index
  
  def index
    return unless verify_params([ :id, :udid, :publisher_app_id ])
    
    @offer = Offer.find_in_cache params[:id]
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    return unless verify_records([ @currency, @offer ])
    
    @complete_action_url = @offer.complete_action_url({
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => params[:click_key],
      :itunes_link_affiliate => params[:itunes_link_affiliate],
    })
  end

private

  def setup
    return unless verify_params([ :data ])

    data_str = SymmetricCrypto.decrypt([ params[:data] ].pack("H*"), SYMMETRIC_CRYPTO_SECRET)
    data = Marshal.load(data_str)
    params.merge!(data)
  end
  
end