class CouponsController < ApplicationController
  prepend_before_filter :decrypt_data_param
  before_filter :setup

  def complete
  end

  private

  def setup
    verify_params([ :currency_id, :offer_id, :app_id ])
    @offer = Offer.find_in_cache(params[:offer_id])
    @coupon = Coupon.find_in_cache(@offer.item_id) if @offer
    @currency = Currency.find_in_cache(params[:currency_id]) if @coupon
    @publisher_app = App.find_in_cache(params[:app_id]) if @currency
    verify_records([ @currency, @offer, @coupon, @publisher_app ])
  end
end
