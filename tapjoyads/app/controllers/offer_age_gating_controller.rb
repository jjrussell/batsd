class OfferAgeGatingController < ApplicationController
  include GetOffersHelper
  prepend_before_filter :decrypt_data_param

  layout 'iphone', :only => :index

  def index
    data = ObjectEncryptor.decrypt(params[:data])
    @offer = Offer.find_in_cache(data[:offer_id])

    @redirect_url = "#{API_URL}/offer_age_gating/redirect?data=#{ObjectEncryptor.encrypt(params)}"
  end

  # passing params[:date_of_birth] to click controller for web_request logging
  def redirect
    @now = Time.zone.now
    @currency = Currency.find_in_cache(params[:currency_id])
    @publisher_app = App.find_in_cache(params[:app_id])

    data = ObjectEncryptor.decrypt(params[:data])
    offer = Offer.find_in_cache(data[:offer_id])

    redirect_to(get_click_url(offer, params[:options].merge!({ :date_of_birth => params[:date_of_birth] })))
  end

end
