class GetOffersController < ApplicationController

  layout 'offerwall', :only => :webpage

  prepend_before_filter :decrypt_data_param
  #before_filter :choose_experiment, :except => [:featured, :image]
  before_filter :set_featured_params, :only => :featured
  before_filter :setup, :except => :image
  before_filter :choose_papaya_experiment, :only => [:index, :webpage]

  after_filter :save_web_request, :except => :image
  after_filter :save_impressions, :only => [:index, :webpage]

  def image
    offer = Offer.find_in_cache(params[:offer_id])
    img = IMGKit.new(offer.get_offers_webpage_preview_url(params[:publisher_app_id]), :width => 320)

    send_data img.to_png, :type => 'image/png', :disposition => 'inline'
  end

  def webpage
    if @currency.get_test_device_ids.include?(params[:udid])
      @test_offers = [ build_test_offer(@publisher_app) ]
      @test_offers << build_test_video_offer(@publisher_app).primary_offer if params[:all_videos] || params[:video_offer_ids].to_s.split(',').include?('test_video')
    end

    set_geoip_data

    if @for_preview
      @offer_list, @more_data_available = [[Offer.find_in_cache(params[:offer_id])], 0]
    else
      @offer_list, @more_data_available = get_offer_list.get_offers(@start_index, @max_items)
    end
  end

  def featured
    set_geoip_data
    if @currency.get_test_device_ids.include?(params[:udid])
      @offer_list = [ build_test_offer(@publisher_app) ]
    else
      @offer_list = [ get_offer_list.weighted_rand ].compact
      if @offer_list.empty?
        @offer_list = [ get_offer_list(Offer::FEATURED_BACKFILLED_OFFER_TYPE).weighted_rand ].compact
      end
    end
    @more_data_available = 0

    if @offer_list.any?
      @web_request.offer_id = @offer_list.first.id
      @web_request.path = 'featured_offer_shown'
    end

    if params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs_redirect'
    end
  end

  def index
    is_server_to_server = params[:redirect] == '1' || (params[:json] == '1' && params[:callback].blank?)
    set_geoip_data(is_server_to_server)
    @offer_list, @more_data_available = get_offer_list.get_offers(@start_index, @max_items)
    if @currency.tapjoy_managed? && params[:source] == 'tj_games'
      @tap_points = PointPurchases.new(:key => "#{params[:publisher_user_id]}.#{@currency.id}").points
    end

    if params[:type] == Offer::CLASSIC_OFFER_TYPE
      render :template => 'get_offers/offers'
    elsif params[:redirect] == '1'
      render :template => 'get_offers/installs_redirect'
    elsif params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs'
    end
  end

private

  def set_featured_params
    params[:type] = Offer::FEATURED_OFFER_TYPE
    params[:source] = 'featured'
    params[:rate_app_offer] = '0'
  end

  def setup
    @for_preview = (params[:action] == 'webpage' && params[:offer_id].present?)
    @save_web_requests = !@for_preview && params[:no_log] != '1'

    required_params = [:app_id] + (@for_preview ? [:offer_id] : [:udid, :publisher_user_id])
    return unless verify_params(required_params)

    @now = Time.zone.now
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 25).to_i

    params[:currency_id] = params[:app_id] if params[:currency_id].blank?
    if params[:currency_selector] == '1'
      @currencies = Currency.find_all_in_cache_by_app_id(params[:app_id])
      @currency = @currencies.select { |c| c.id == params[:currency_id] }.first
    else
      @currency = Currency.find_in_cache(params[:currency_id])
      @currency = nil if @currency.present? && @currency.app_id != params[:app_id]
    end
    @publisher_app = App.find_in_cache(params[:app_id])
    return unless verify_records([ @currency, @publisher_app ])

    unless @for_preview
      @device = Device.new(:key => params[:udid])
      @device.set_publisher_user_id(params[:app_id], params[:publisher_user_id])
      @device.set_last_run_time(TEXTFREE_PUB_APP_ID) if params[:app_id] == TEXTFREE_PUB_APP_ID && (!@device.has_app?(TEXTFREE_PUB_APP_ID) || (Time.zone.now - @device.last_run_time(TEXTFREE_PUB_APP_ID)) > 24.hours)
      @device.save if @device.changed?
    end

    params[:source] = 'offerwall' if params[:source].blank?
    params[:exp] = nil if params[:type] == Offer::CLASSIC_OFFER_TYPE

    if @save_web_requests
      wr_path = params[:source] == 'featured' ? 'featured_offer_requested' : 'offers'
      @web_request = WebRequest.new(:time => @now)
      @web_request.put_values(wr_path, params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
      @web_request.viewed_at = @now
      @web_request.offerwall_start_index = @start_index
      @web_request.offerwall_max_items = @max_items
    end
    @show_papaya = false
    @papaya_offers = {}

    #TJG app offers will show wifi only icon (except for android there's no cell download limit yet), for offerwall only windows phone will show the icon
    @show_wifi_only = (params[:show_wifi_only] == '1') || (params[:device_type] == 'windows')
  end

  def get_offer_list(type = nil)
    OfferList.new(
      :publisher_app        => @publisher_app,
      :device               => @device,
      :currency             => @currency,
      :device_type          => params[:device_type],
      :geoip_data           => @geoip_data,
      :type                 => type || params[:type],
      :app_version          => params[:app_version],
      :include_rating_offer => params[:rate_app_offer] != '0',
      :direct_pay_providers => params[:direct_pay_providers].to_s.split(','),
      :exp                  => params[:exp],
      :library_version      => params[:library_version],
      :os_version           => params[:os_version],
      :source               => params[:source],
      :screen_layout_size   => params[:screen_layout_size],
      :video_offer_ids      => params[:video_offer_ids].to_s.split(','),
      :all_videos           => params[:all_videos]
    )
  end

  def set_geoip_data(is_server_to_server = false)
    if is_server_to_server && params[:device_ip].blank?
      @geoip_data = {}
    else
      @geoip_data = get_geoip_data
    end

    if @geoip_data[:country] != 'CN' && params[:country_code].present?
      @geoip_data[:country] = params[:country_code]
    end
  end

  def save_web_request
    @web_request.save if @save_web_requests
  end

  def save_impressions
    if @save_web_requests
      @offer_list.each_with_index do |offer, i|
        @web_request.replace_path('offerwall_impression')
        @web_request.offer_id = offer.id
        @web_request.offerwall_rank = i + @start_index + 1
        @web_request.offerwall_rank_score = offer.rank_score
        # @web_request.save
      end
    end
  end

  def choose_papaya_experiment
    if !@for_preview && @device.is_papayan?
      choose_experiment
      if params[:exp] == '1'
        @show_papaya = true
        @papaya_offers = OfferCacher.get_papaya_offers || {}
      end
    end
  end

end
