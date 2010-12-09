class FullscreenAdController < ApplicationController
  
  layout 'iphone'
  
  def index
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    @offer = Offer.find_in_cache(params[:offer_id])
    @displayer = params[:displayer_app_id].present? ? App.find_in_cache(params[:displayer_app_id]) : nil
    @viewed_at = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now
  end
  
  def test_offer
    @publisher_app = App.find_in_cache(params[:publisher_app_id])
    @currency = Currency.find_in_cache(params[:currency_id] || params[:publisher_app_id])
    @offer = build_test_offer(@publisher_app, @currency)
    @displayer = params[:displayer_app_id].present? ? App.find_in_cache(params[:displayer_app_id]) : nil
    @viewed_at = params[:viewed_at].present? ? Time.zone.at(params[:viewed_at].to_f) : Time.zone.now
    render :action => :index
  end
  
end