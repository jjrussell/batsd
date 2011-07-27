class GetOffersController < ApplicationController
  
  layout 'iphone', :only => :webpage
  
  prepend_before_filter :decrypt_data_param
  before_filter :fix_tapulous
  before_filter :choose_experiment, :except => :featured
  before_filter :set_featured_params, :only => :featured
  before_filter :setup
  
  after_filter :save_web_request

  DEVICES_FOR_REDESIGN = Set.new([
    'c1bd5bd17e35e00b828c605b6ae6bf283d9bafa1', # Stehpen
    'a850ff9e654965299104754249ceaa5f7b61a69e', # Eric iPhone
    'b4c86b4530a0ee889765a166d80492b46f7f3636', # Ryan iPhone
    '36fa4959f5e1513ba1abd95e68ad40b75b237f15', # Kai iPad
    '5c46e034cd005e5f2b08501820ecb235b0f13f33', # HJ iPhone
    '355031040923092',                          # Linda Nexus S
    'a100000d9833c5'                            # Stephen Evo
  ])

  def webpage
    if @currency.get_test_device_ids.include?(params[:udid])
      @test_offer = build_test_offer(@publisher_app)
    end
    
    set_geoip_data
    @offer_list, @more_data_available = get_offer_list.get_offers(@start_index, @max_items)

    if @currency.hide_rewarded_app_installs_for_version?(params[:app_version], params[:source]) || DEVICES_FOR_REDESIGN.include?(params[:udid])
      render :template => 'get_offers/webpage_redesign', :layout => 'iphone_redesign'
    end
  end

  def featured
    if @currency.get_test_device_ids.include?(params[:udid])
      @geoip_data = get_geoip_data
      @geoip_data[:country] = params[:country_code] if params[:country_code].present?
      @offer_list = [ build_test_offer(@publisher_app) ]
    else
      set_geoip_data
      @offer_list = [ get_offer_list.weighted_rand ].compact
    end
    @more_data_available = 0
    
    if @offer_list.any?
      @web_request.offer_id = @offer_list.first.id
      @web_request.add_path('featured_offer_shown')
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

  def fix_tapulous
    # special code for Tapulous not sending udid
    if params[:app_id] == 'e2479a17-ce5e-45b3-95be-6f24d2c85c6f'
      params[:udid] = params[:publisher_user_id] if params[:udid].blank?
    end
  end
  
  def set_featured_params
    params[:type] = Offer::FEATURED_OFFER_TYPE
    params[:source] = 'featured'
    params[:rate_app_offer] = '0'
  end
  
  def setup
    return unless verify_params([ :app_id, :udid, :publisher_user_id ])
    
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
    
    @device = Device.new(:key => params[:udid])
    if @device.opted_out?
      @offer_list = []
      @more_data_available = 0
      if params[:action] == 'webpage'
        @message = "You have opted out."
        render :template => 'get_offers/webpage'
      elsif params[:json] == '1'
        render :template => 'get_offers/installs_json', :content_type => 'application/json'
      else
        render :template => 'get_offers/installs_redirect'
      end
      return
    end
    
    #TO REMOVE: hackey stuff for doodle buddy, remove on Jan 1, 2011
    doodle_buddy_holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    doodle_buddy_regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    params[:app_id] = doodle_buddy_regular_id if params[:app_id] == doodle_buddy_holiday_id
    
    params[:source] = 'offerwall' if params[:source].blank?
    params[:exp] = nil if params[:type] == Offer::CLASSIC_OFFER_TYPE
    
    wr_path = params[:source] == 'featured' ? 'featured_offer_requested' : 'offers'
    @web_request = WebRequest.new(:time => @now)
    @web_request.put_values(wr_path, params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    @web_request.put('viewed_at', @now.to_f.to_s)
  end
  
  def get_offer_list(options = {})
    @offer_list = OfferList.new(
      :publisher_app        => @publisher_app,
      :device               => @device,
      :currency             => @currency,
      :device_type          => params[:device_type],
      :geoip_data           => @geoip_data,
      :type                 => params[:type],
      :app_version          => params[:app_version],
      :include_rating_offer => params[:rate_app_offer] != '0',
      :direct_pay_providers => params[:direct_pay_providers].to_s.split(','),
      :exp                  => params[:exp],
      :library_version      => params[:library_version],
      :os_version           => params[:os_version],
      :source               => params[:source],
      :screen_layout_size   => params[:screen_layout_size])
  end
  
  def save_web_request
    @web_request.save
  end
  
  def set_geoip_data(is_server_to_server = false)
    if is_server_to_server && params[:device_ip].blank?
      @geoip_data = {}
    else
      @geoip_data = get_geoip_data
    end
    @geoip_data[:country] = params[:country_code] if params[:country_code].present?
  end
  
end
