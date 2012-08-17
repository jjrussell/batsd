class OfferAgeGatingController < ApplicationController
  include GetOffersHelper
  prepend_before_filter :decrypt_data_param

  layout 'iphone', :only => :index

  def index
    @now = Time.zone.now
    @currency = Currency.find_in_cache(params[:currency_id])
    @publisher_app = App.find_in_cache(params[:app_id])

    @offer = Offer.find_in_cache params[:id]
    @click_url = get_click_url(@offer, params[:options])
  end

end
