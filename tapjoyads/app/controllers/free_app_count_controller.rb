class FreeAppCountController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid])

    currency = Currency.find_in_cache(params[:app_id])
    publisher_app = App.find_in_cache(params[:app_id])
    return unless verify_records([ currency, publisher_app ])

    currency.only_free_offers = true
    offer_list = OfferList.new(
      :publisher_app      => publisher_app,
      :device             => Device.new(:key => params[:udid]),
      :currency           => currency,
      :device_type        => params[:device_type],
      :os_version         => params[:os_version],
      :screen_layout_size => params[:screen_layout_size])

    @free_app_count = offer_list.get_offers(0, 1000).first.length
  end
end
