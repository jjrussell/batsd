class ActionOffersController < ApplicationController
  
  layout 'iphone', :only => :show
  
  def show
    return unless verify_params([ :id, :advertiser_app_id, :currency_id ])
    
    @action_offer = ActionOffer.find_in_cache params[:id]
    @app = App.find_in_cache params[:advertiser_app_id]
    @currency = Currency.find_in_cache params[:currency_id]
    @offer = Offer.find_in_cache params[:id]
    return unless verify_records([ @action_offer, @app, @currency, @offer ])
  end
  
end