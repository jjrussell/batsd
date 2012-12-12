class GetOffersController < ApplicationController
  include GetOffersHelper
  include AdminDeviceLastRun::ControllerExtensions

  layout 'offerwall', :only => [:webpage, :webpage_cross_promo]

  prepend_before_filter :decrypt_data_param
  before_filter :set_featured_params, :only => :featured
  before_filter :lookup_udid, :set_publisher_user_id, :setup, :set_algorithm, :except => [:webpage_cross_promo, :featured_cross_promo]

  tracks_admin_devices(:only => [:webpage, :index])

  after_filter :save_web_request
  after_filter :save_impressions, :only => [:index, :webpage]

  VIEW_MAP = {
    :control => {
      :autoload => false, :actionLocation => 'right',
      :deepLink => false, :showBanner => false,
      :showActionLine => true, :showCostBalloon => false,
      :showCurrentApp => false, :squircles => false,
      :viewID => 'control', :showActionArrow => false
    }
  }

  VIEW_MAP[:test] = VIEW_MAP[:control].dup # no changes for this experiment

  def webpage_cross_promo
    return unless verify_params([:app_id])
    currency = Currency.find_non_rewarded_currency_in_cache_by_app_id(params[:app_id])
    return unless verify_records([currency])
    redirect_to params.merge({:action => :webpage, :currency_id => currency.id})
  end

  def webpage
    @sdk9plus = library_version >= '9'
    if @currency.has_test_device?(params[:udid] || params[:mac_address])
      @test_offers = [ @publisher_app.test_offer ]
      if library_version >= '8.3' ||
           params[:all_videos] ||
           params[:video_offer_ids].to_s.split(',').include?('test_video')
        @test_offers << @publisher_app.test_video_offer.primary_offer
      end
    end

    if @for_preview
      @offer_list, @more_data_available = [[Offer.find_in_cache(params[:offer_id], :queue => true )], 0]
    else
      @offer_list, @more_data_available = get_offer_list.get_offers(@start_index, @max_items)
    end

    #TODO(nixoncd): uncomment when currency sale view gets cleaned up
    #@currency_sale = @currency.active_currency_sale
    #if @currency_sale
      #if @currency_sale.message.present?
        #@currency_sale_message = @currency_sale.message
      #else
        #@currency_sale_message = I18n.t('text.currency_sale.sale_default_message', :publisher => @publisher_app.name, :multiplier => @currency_sale.multiplier_to_string, :currency_name => @currency.name)
      #end
    #end

    set_webpage_parameters
    if params[:json] == '1'
      if !@publisher_app.uses_non_html_responses? && params[:source] != 'tj_games'
        @publisher_app.queue_update_attributes(:uses_non_html_responses => true)
      end
      render :json => @final.to_json, :callback => params[:callback]
    else
      render :template => 'get_offers/webpage'
    end
  end

  def featured_cross_promo
    return unless verify_params([:app_id])
    currency = Currency.find_non_rewarded_currency_in_cache_by_app_id(params[:app_id])
    return unless verify_records([currency])
    redirect_to params.merge({:action => :featured, :currency_id => currency.id})
  end

  def featured
    if @currency.has_test_device?(params[:udid] || params[:mac_address])
      @offer_list = [ @publisher_app.test_offer ]
    elsif @for_preview
      offer = merge_preview_attributes(Offer.find_in_cache(params[:offer_id]))
      @offer_list = [ offer ]
    else
      @offer_list = [ get_offer_list.weighted_rand ].compact
      if @offer_list.empty?
        @offer_list = [ get_offer_list(Offer::FEATURED_BACKFILLED_OFFER_TYPE).weighted_rand ].compact
      end
    end
    @more_data_available = 0

    if @offer_list.any? && @web_request
      @web_request.offer_id = @offer_list.first.id
      @web_request.path = 'featured_offer_shown'
    end

    if !@publisher_app.uses_non_html_responses? && params[:source] != 'tj_games'
      @publisher_app.queue_update_attributes(:uses_non_html_responses => true)
    end

    if params[:format] == 'html'
      @offer = @offer_list.first

      # for pixel tracking
      params[:offer_id] = @offer.id
      @encrypted_params = ObjectEncryptor.encrypt(params)

      if @offer.banner_creatives.present? && !@offer.banner_creatives.any? { |size| Offer::FEATURED_AD_SIZES.include?(size) }
        # use legacy layout if offer ONLY has FEATURED_AD_LEGACY_SIZES
        render :layout => "iphone", :template => 'get_offers/featured_legacy'
      else # new layout
        render :template => 'get_offers/featured'
      end
    elsif params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs_redirect'
    end
  end

  def index
    @offer_list, @more_data_available = get_offer_list.get_offers(@start_index, @max_items)
    if @currency.tapjoy_managed? && params[:source] == 'tj_games'
      @tap_points = PointPurchases.new(:key => "#{params[:publisher_user_id]}.#{@currency.id}").points
    end

    if !@publisher_app.uses_non_html_responses? && params[:source] != 'tj_games'
      @publisher_app.queue_update_attributes(:uses_non_html_responses => true)
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
    params[:format] = 'xml' unless params[:format] == 'html'
  end

  def merge_preview_attributes(offer)
    # for the benefit of previewing ads in the admin, we can override offer fields here -- this affects
    # preview rendering only, as the override attributes are not saved
    offer_preview_attributes = (params.delete(:offer_preview_attributes) || {}).slice(:featured_ad_content, :featured, :featured_ad_color, :featured_ad_action)
    offer_preview_attributes[:featured]              = (offer_preview_attributes[:featured] == "true")
    offer.attributes = offer_preview_attributes

    offer
  end

  def setup
    @for_preview = (['webpage', 'featured'].include?(params[:action]) && params[:offer_id].present?)
    @save_web_requests = !@for_preview && params[:no_log] != '1'
    @server_to_server = server_to_server?

    required_params = [:app_id] + (@for_preview ? [:offer_id] : [:udid, :publisher_user_id])
    return unless verify_params(required_params)

    @now = Time.zone.now
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 25).to_i

    params[:impression_id] = UUIDTools::UUID.random_create.to_s
    params[:currency_id] = params[:app_id] if params[:currency_id].blank?
    if params[:currency_selector] == '1'
      @currencies = Currency.find_all_in_cache_by_app_id(params[:app_id])
      @currency = @currencies.select { |c| c.id == params[:currency_id] }.first
      @supports_rewarded = @currencies.any? { |c| c.rewarded? }
    else
      @currency = Currency.find_in_cache(params[:currency_id], :queue => true)
      if @currency.present?
        @supports_rewarded = @currency.rewarded?
        @currency = nil if @currency.app_id != params[:app_id]
      end
    end
    @publisher_app = App.find_in_cache(params[:app_id], :queue => true)
    return unless verify_records([ @currency, @publisher_app ])

    unless @for_preview
      @device = Device.new(:key => params[:udid])
      @device.screen_layout_size = params[:screen_layout_size] if params[:screen_layout_size].present?
      @device.mobile_country_code = params[:mobile_country_code] if params[:mobile_country_code].present?
      @device.mobile_network_code = params[:mobile_network_code] if params[:mobile_network_code].present?
      @device.set_publisher_user_id(params[:app_id], params[:publisher_user_id])
      @device.set_last_run_time(TEXTFREE_PUB_APP_ID) if params[:app_id] == TEXTFREE_PUB_APP_ID && (!@device.has_app?(TEXTFREE_PUB_APP_ID) || (Time.zone.now - @device.last_run_time(TEXTFREE_PUB_APP_ID)) > 24.hours)
      @device.save if @device.changed?
    end

    params[:source] = 'offerwall' if params[:source].blank?

    # No experiment running currently
    choose_experiment(:auditioning_test)

    if @save_web_requests
      @web_request = generate_web_request
      update_web_request_store_name(@web_request, nil, @publisher_app)
    end
    @show_papaya = false
    @papaya_offers = {}

    if library_version.control_video_caching?
      # Allow developers to override app settings to hide videos
      if params[:hide_videos] =~ /^1|true$/
        @all_videos = false
        @video_offer_ids = []
      else
        # If video streaming is on for this connection type we want to return all videos
        @all_videos = @publisher_app.videos_stream_on?(params[:connection_type])
        # But if it's not on, and caching is enabled, we will have gotten back a list of cached videos
        @video_offer_ids = params[:video_offer_ids].to_s.split(',')
      end
    else
      @all_videos = params[:all_videos]
      @video_offer_ids = params[:video_offer_ids].to_s.split(',')
    end

    #TJG app offers will show wifi only icon (except for android there's no cell download limit yet), for offerwall only windows phone will show the icon
    @show_wifi_only = (params[:show_wifi_only] == '1') || (params[:device_type] == 'windows')
  end

  def get_offer_list(type = nil)
    OfferList.new(
      :publisher_app        => @publisher_app,
      :device               => @device,
      :currency             => @currency,
      :device_type          => params[:device_type],
      :geoip_data           => geoip_data,
      :type                 => type || params[:type],
      :app_version          => params[:app_version],
      :direct_pay_providers => params[:direct_pay_providers].to_s.split(','),
      :exp                  => params[:exp],
      :library_version      => params[:library_version],
      :os_version           => params[:os_version],
      :source               => params[:source],
      :screen_layout_size   => params[:screen_layout_size],
      :video_offer_ids      => @video_offer_ids,
      :all_videos           => @all_videos,
      :algorithm            => @algorithm,
      :algorithm_options    => @algorithm_options,
      :mobile_carrier_code  => "#{params[:mobile_country_code]}.#{params[:mobile_network_code]}",
      :store_name           => params[:store_name]
    )
  end

  def save_web_request
    @web_request.save if @save_web_requests
  end

  def save_impressions
    if @save_web_requests
      web_request = generate_web_request
      update_web_request_store_name(web_request, nil, @publisher_app)
      @offer_list.each_with_index do |offer, i|
        web_request.replace_path('offerwall_impression')
        web_request.offer_id = offer.id
        web_request.offerwall_rank = i + @start_index + 1
        web_request.offerwall_rank_score = offer.rank_score
        web_request.cached_offer_list_id = offer.cached_offer_list_id
        web_request.cached_offer_list_type = offer.cached_offer_list_type
        web_request.auditioning = offer.auditioning
        web_request.save

        # for third party tracking vendors
        offer.queue_impression_tracking_requests(
          :ip_address       => ip_address,
          :udid             => params[:udid],
          :publisher_app_id => params[:app_id])
      end
    end
  end

  def set_algorithm
    if params[:source] == 'offerwall'
      @algorithm = '101'
      @algorithm_options = {:skip_country => true}
    elsif params[:source] == 'tj_games'
      @algorithm = '237'
      @algorithm_options = {:skip_country => true, :skip_currency => true}
    end
    @algorithm = '280' if params[:exp] == 'auditioning_test'
  end

  def server_to_server?
    if params[:action] == 'index'
      return false if params[:data].present?
      return true if params[:redirect] == '1' || (params[:json] == '1' && params[:callback].blank?)
    end
    params[:library_version] == 'server'
  end

  def set_webpage_parameters
    # manual override > result of choose_experiment > :control
    view_id = params[:viewID] || params[:exp] || :control
    view = VIEW_MAP.fetch(view_id.to_sym) { {} }

    offer_array = []
    @offer_list.each_with_index do |offer, index|
      hash                      = {}
      hash[:cost]              = visual_cost(offer)
      hash[:iconURL]           = offer.item_type == 'VideoOffer' ? offer.video_icon_url : offer.get_icon_url(:source => :cloudfront, :size => '57')
      hash[:payout]            = @currency.get_visual_reward_amount(offer, params[:display_multiplier])
      hash[:redirectURL]       = offer.age_gate? ? get_age_gating_url(offer, { :offerwall_rank => (@start_index + index + 1), :view_id => view_id }) : get_click_url(offer, { :offerwall_rank => (@start_index + index + 1), :view_id => view_id })
      hash[:requiresWiFi]      = offer.wifi_only? if @show_wifi_only
      hash[:title]             = offer.ad_name
      hash[:type]              = offer.item_type == 'VideoOffer' ? 'video' : offer.item_type == 'ActionOffer' || offer.item_type == 'GenericOffer' ? 'series' : offer.item_type == 'App' ? 'download' : offer.item_type
      offer_array << hash
    end

    @obj = {
             :autoload => true, :actionLocation => 'left',
             :deepLink => true, :maxlength =>  70,
             :showBanner => true, :showActionLine => true,
             :showCostBalloon => false, :showCurrentApp => false,
             :squircles => true, :orientation => 'landscape',
             :offers => offer_array, :currencyName => @currency.name,
             :currentAppName => @publisher_app.name
           }

    @obj[:currentIconURL]      = IconHandler.get_icon_url(:source => :cloudfront, :size => '57', :icon_id => IconHandler.hashed_icon_id(@publisher_app.id))
    @obj[:message]             = t('text.offerwall.instructions', { :currency => @currency.name.downcase})
    @obj[:records]             = @more_data_available if @more_data_available
    @obj[:rewarded]            = @supports_rewarded

    @final = @obj.merge(view);
  end

end
