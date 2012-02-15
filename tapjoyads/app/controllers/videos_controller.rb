class VideosController < ApplicationController
  layout 'games', :only => :complete

  before_filter :setup

  def index
    @offer_list = offer_list.get_offers(0, 100).first

    if @currency.get_test_device_ids.include?(params[:udid])
      @offer_list.insert(0, build_test_video_offer(@publisher_app).primary_offer)
    end
  end

  def complete
    @video_offer = VideoOffer.find_in_cache(params[:id])
    @offer = Offer.find_in_cache(params[:offer_id])
    return unless verify_records([ @video_offer, @offer ])
  end

  private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params([ :app_id, :udid, :currency_id, :publisher_user_id ])

    @device = Device.new(:key => params[:udid])
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache(params[:currency_id])
    @currency = nil if @currency.present? && @currency.app_id != params[:app_id]
    return unless verify_records([ @publisher_app, @currency ])
  end

  def offer_list
    OfferList.new(
      :device             => @device,
      :publisher_app      => @publisher_app,
      :currency           => @currency,
      :device_type        => params[:device_type],
      :geoip_data         => get_geoip_data,
      :os_version         => params[:os_version],
      :type               => Offer::VIDEO_OFFER_TYPE,
      :library_version    => params[:library_version],
      :screen_layout_size => params[:screen_layout_size])
  end

end
