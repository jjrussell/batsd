class GetOffersController < ApplicationController
  
  layout 'iphone', :only => :webpage
  
  before_filter :fix_tapulous
  before_filter :choose_experiment, :except => :featured
  # TO REMOVE - once the tap defense connect bug has been fixed and is sufficiently adopted
  before_filter :fake_connect_call, :only => :featured
  # END TO REMOVE
  before_filter :set_featured_params, :only => :featured
  before_filter :setup
  
  after_filter :save_web_request
  
  def webpage
    if @currency.get_test_device_ids.include?(params[:udid])
      @test_offer = build_test_offer(@publisher_app, @currency)
    end
    
    set_offer_list(:is_server_to_server => false)
    
    # TO REMOVE - when gameview integrates properly
    @message = nil
    if params[:featured_offer].present?
      featured_offer = Offer.find_in_cache(params[:featured_offer])
      primary_offer = Offer.find_in_cache(featured_offer.item_id)
      
      if featured_offer.featured? && @offer_list.include?(primary_offer)
        redirect_to featured_offer.get_click_url(@publisher_app, params[:publisher_user_id], params[:udid], @currency.id, 'featured', params[:app_version], @now, nil, params[:exp])
        return
      end
      @message = "You have already installed #{featured_offer.name}. You can still complete " +
          "one of the offers below to earn #{@currency.name}."
    end
    # END TO REMOVE
  end
  
  def featured
    if @currency.get_test_device_ids.include?(params[:udid])
      @offer_list = [ build_test_offer(@publisher_app, @currency) ]
    else
      set_offer_list(:is_server_to_server => false)
      unless @offer_list.empty?
        weight_scale = 1 - @offer_list.last.rank_score
        weights = @offer_list.collect { |offer| offer.rank_score + weight_scale }
        @offer_list = [ @offer_list.weighted_rand(weights) ]
      end
    end
    @more_data_available = 0
    
    @web_request.add_path('featured_offer_shown') unless @offer_list.empty?
    
    if params[:json] == '1'
      render :template => 'get_offers/installs_json', :content_type => 'application/json'
    else
      render :template => 'get_offers/installs_redirect'
    end
  end
  
  def index
    is_server_to_server = params[:redirect] == '1' || (params[:json] == '1' && params[:callback].blank?)
    set_offer_list(:is_server_to_server => is_server_to_server)
    
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
    params[:start] = '0'
    params[:max] = '999'
    params[:source] = 'featured'
  end
  
  def setup
    return unless verify_params([ :app_id, :udid, :publisher_user_id ])
    
    @now = Time.zone.now
    @start_index = (params[:start] || 0).to_i
    @max_items = (params[:max] || 25).to_i
    
    params[:currency_id] = params[:app_id] if params[:currency_id].blank?
    @currencies = Currency.find_all_in_cache_by_app_id(params[:app_id])
    @currency = @currencies.select { |c| c.id == params[:currency_id] }.first
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
    
    ##
    # Gameview hardcodes 'iphone' as their device type. This screws up real iphone-only targeting.
    # Set the device type to 'ipod touch' for gameview until they fix their issue.
    if @publisher_app.partner_id == "e9a6d51c-cef9-4ee4-a2c9-51eef1989c4e" && !@publisher_app.is_android?
      params[:device_type] = 'ipod touch'
    end
    
    #TO REMOVE: hackey stuff for doodle buddy, remove on Jan 1, 2011
    doodle_buddy_holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    doodle_buddy_regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    params[:app_id] = doodle_buddy_regular_id if params[:app_id] == doodle_buddy_holiday_id
    
    params[:source] = 'offerwall' if params[:source].blank?
    params[:exp] = nil if params[:type] == Offer::CLASSIC_OFFER_TYPE
    # TO REMOVE - when gameview integrates properly
    params[:exp] = nil if params[:featured_offer].present?
    # END TO REMOVE
    
    wr_path = params[:source] == 'featured' ? 'featured_offer_requested' : 'offers'
    @web_request = WebRequest.new(:time => @now)
    @web_request.put_values(wr_path, params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    @web_request.put('viewed_at', @now.to_f.to_s)
  end
  
  def set_offer_list(options = {})
    is_server_to_server = options.delete(:is_server_to_server) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    if is_server_to_server && params[:device_ip].blank?
      geoip_data = {}
    else
      geoip_data = get_geoip_data
    end
    
    type = case params[:type]
    when Offer::FEATURED_OFFER_TYPE
      Offer::FEATURED_OFFER_TYPE
    when Offer::CLASSIC_OFFER_TYPE
      Offer::CLASSIC_OFFER_TYPE
    else
      Offer::DEFAULT_OFFER_TYPE
    end
    
    @offer_list, @more_data_available = @publisher_app.get_offer_list(params[:udid],
        :device => @device,
        :currency => @currency,
        :device_type => params[:device_type],
        :geoip_data => geoip_data,
        :type => type,
        :required_length => (@start_index + @max_items),
        :app_version => params[:app_version],
        :reject_rating_offer => params[:rate_app_offer] == '0',
        :direct_pay_providers => params[:direct_pay_providers].to_s.split(','),
        :exp => params[:exp])
    @offer_list = @offer_list[@start_index, @max_items] || []
  end
  
  def save_web_request
    @web_request.save
  end
  
  # TO REMOVE - once the tap defense connect bug has been fixed and is sufficiently adopted
  def fake_connect_call
    if params[:app_id] == '2349536b-c810-47d7-836c-2cd47cd3a796' && (params[:app_version] == '3.2.2' || params[:app_version] == '3.2.1') && params[:library_version] == '5.0.1'
      
      Rails.logger.info_with_time("Check conversions and maybe add to sqs") do
        click = Click.new(:key => "#{params[:udid]}.#{params[:app_id]}")
        unless (click.attributes.empty? || click.installed_at)
          logger.info "Added conversion to sqs queue"
          message = { :click => click.serialize(:attributes_only => true), :install_timestamp => Time.zone.now.to_f.to_s }.to_json
          Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
        end
      end
      
      web_request = WebRequest.new
      web_request.put_values('connect', params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    
      device = Device.new(:key => params[:udid])
      path_list = device.set_app_ran(params[:app_id], params)
      path_list.each do |path|
        web_request.add_path(path)
      end
      
      device.save
      web_request.save
    end
  end
  # END TO REMOVE
  
end
