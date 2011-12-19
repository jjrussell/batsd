class VideosController < ApplicationController

  before_filter :setup

  def index
    @offer_list = OfferList.new(
      :device             => @device,
      :publisher_app      => @publisher_app,
      :currency           => @currency,
      :device_type        => params[:device_type],
      :geoip_data         => @geoip_data,
      :os_version         => params[:os_version],
      :type               => Offer::VIDEO_OFFER_TYPE,
      :library_version    => params[:library_version],
      :screen_layout_size => params[:screen_layout_size]).get_offers(0, 100)
    @offer_list.insert(0, build_test_video_offer(@publisher_app).primary_offer) if @currency.get_test_device_ids.include?(params[:udid])
  end
  
  def complete
    @offer = Offer.find_in_cache(params[:id])
    return unless verify_records( [ @offer ])
  end

  private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([ :app_id, :udid, :currency_id, :publisher_user_id ])

    @geoip_data = get_geoip_data
    @geoip_data[:country] = params[:country_code] if params[:country_code].present?

    @device = Device.new(:key => params[:udid])
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache(params[:currency_id])
    @currency = nil if @currency.present? && @currency.app_id != params[:app_id]
    return unless verify_records([ @publisher_app, @currency ])
  end

end
