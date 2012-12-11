class VideosController < ApplicationController
  layout 'api-games', :only => :complete

  prepend_before_filter :decrypt_data_param, :only => [:complete]
  before_filter :lookup_udid, :set_publisher_user_id, :setup

  def index
    @options = Hash.new

    if library_version.control_video_caching?
      @options.merge!({
        :cache_auto   => @publisher_app.videos_cache_auto?,
        :cache_wifi   => @publisher_app.videos_cache_wifi?,
        :cache_mobile => @publisher_app.videos_cache_3g?
      })
    end

    if @show_cached_videos
      @offer_list = offer_list.get_offers(0, 100).first

      if @currency.has_test_device?(params[:udid] || params[:mac_address])
        @offer_list.unshift(@publisher_app.test_video_offer.primary_offer)
      end
    else
      @offer_list = []
    end
  end

  def complete
    return unless verify_params(:id, :offer_id)

    if params[:id] == 'test_video'
      @video_offer = @publisher_app.test_video_offer
      @offer       = @publisher_app.test_video_offer.primary_offer
    else
      @video_offer = VideoOffer.find_in_cache(params[:id])
      @offer       = Offer.find_in_cache(params[:offer_id])
    end

    return unless verify_records(@video_offer, @offer)

    @video_buttons = @video_offer.video_buttons_for_device_type(device_type)[0..1]
  end

  private

  def setup
    params[:currency_id] ||= params[:app_id]
    return unless verify_params(:app_id, :udid, :currency_id, :publisher_user_id)

    @device = Device.new(:key => params[:udid])
    @publisher_app = App.find_in_cache(params[:app_id])
    @currency = Currency.find_in_cache(params[:currency_id])
    @currency = nil if @currency.present? && @currency.app_id != params[:app_id]
    return unless verify_records(@publisher_app, @currency)

    if library_version.control_video_caching?
      @hide_videos = params[:hide_videos] =~ /^1|true$/
      @show_cached_videos = !@hide_videos && @publisher_app.videos_cache_on?(params[:connection_type])
    else
      @show_cached_videos = true
    end
  end

  def offer_list
    OfferList.new(
      :device              => @device,
      :publisher_app       => @publisher_app,
      :currency            => @currency,
      :device_type         => params[:device_type],
      :geoip_data          => geoip_data,
      :os_version          => params[:os_version],
      :type                => Offer::VIDEO_OFFER_TYPE,
      :library_version     => params[:library_version],
      :store_name          => params[:store_name])
  end
end
