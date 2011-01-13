class ActionOffersController < ApplicationController
  
  layout 'iphone', :only => :show
  
  def show
    @action_offer = ActionOffer.find_in_cache params[:id]
    @app = App.find_in_cache @action_offer.app_id
    @currency = Currency.find_in_cache params[:currency_id]
    @offer = Offer.find_in_cache @action_offer.id
  end
  
end