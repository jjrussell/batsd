class ClickController < ApplicationController
  layout 'iphone'
  
  before_filter :decrypt_data_param
  before_filter :setup
  before_filter :validate_click, :except => [ :test_offer, :test_video_offer ]
  before_filter :determine_link_affiliates, :only => :app
  
  after_filter :save_web_request, :except => [ :test_offer, :test_video_offer ]
  
  def app
    create_click('install')
    handle_pay_per_click
    
    redirect_to(get_destination_url)
  end
  
  def action
    create_click('action')
    handle_pay_per_click
    
    redirect_to(get_destination_url)
  end
  
  def generic
    create_click('generic')
    handle_pay_per_click
    
    redirect_to(get_destination_url)
  end
  
  def rating
    create_click('rating')
    handle_pay_per_click
    
    redirect_to(get_destination_url)
  end
  
  def video
    create_click('video')
    handle_pay_per_click
    
    render :text => 'OK'
  end
  
  def test_offer
    publisher_app = App.find_in_cache(params[:publisher_app_id])
    return unless verify_records([ @currency, publisher_app ])
    
    unless @currency.get_test_device_ids.include?(params[:udid])
      raise "not a test device"
    end
    
    @test_offer = build_test_offer(publisher_app)
    
    test_reward = Reward.new
    test_reward.type              = 'test_offer'
    test_reward.udid              = params[:udid]
    test_reward.publisher_user_id = params[:publisher_user_id]
    test_reward.currency_id       = params[:currency_id]
    test_reward.publisher_app_id  = params[:publisher_app_id]
    test_reward.advertiser_app_id = params[:publisher_app_id]
    test_reward.offer_id          = params[:publisher_app_id]
    test_reward.currency_reward   = @currency.get_reward_amount(@test_offer)
    test_reward.publisher_amount  = 0
    test_reward.advertiser_amount = 0
    test_reward.tapjoy_amount     = 0
    
    message = test_reward.serialize
    Sqs.send_message(QueueNames::SEND_CURRENCY, message)
  end
  
  def test_video_offer
    return unless verify_records([ @currency ])
    
    raise "not a test device" unless @currency.get_test_device_ids.include?(params[:udid])
    
    test_reward = Reward.new
    test_reward.type              = 'test_video_offer'
    test_reward.udid              = params[:udid]
    test_reward.publisher_user_id = params[:publisher_user_id]
    test_reward.currency_id       = params[:currency_id]
    test_reward.publisher_app_id  = params[:publisher_app_id]
    test_reward.advertiser_app_id = params[:publisher_app_id]
    test_reward.offer_id          = params[:publisher_app_id]
    test_reward.currency_reward   = @currency.get_reward_amount(@offer)
    test_reward.publisher_amount  = 0
    test_reward.advertiser_amount = 0
    test_reward.tapjoy_amount     = 0
    
    message = test_reward.serialize
    Sqs.send_message(QueueNames::SEND_CURRENCY, message)
  end
  
private
  
  def setup
    return false unless verify_params([ :data ])
    
    @now = Time.zone.now
    if params[:offer_id] == 'test_video_id'
      publisher_app = App.find_in_cache(params[:publisher_app_id])
      return unless verify_records([ publisher_app ])
      
      @offer = build_test_video_offer(publisher_app).primary_offer
    else
      @offer = Offer.find_in_cache(params[:offer_id])
    end
    @currency = Currency.find_in_cache(params[:currency_id])
    required_records = [ @offer, @currency ]
    if params[:displayer_app_id].present?
      @displayer_app = App.find_in_cache(params[:displayer_app_id])
      required_records << @displayer_app
    end
    return unless verify_records(required_records)
    
    if Time.zone.at(params[:viewed_at]) < (@now - 24.hours)
      build_web_request('expired_click')
      save_web_request
      @destination_url = get_destination_url
      render_unavailable_offer
      return
    end
    
    @device = Device.new(:key => params[:udid])
    
    # Hottest App sends the same publisher_user_id for every click
    if params[:publisher_app_id] == '469f7523-3b99-4b42-bcfb-e18d9c3c4576'
      params[:publisher_user_id] = params[:udid]
    end
  end
  
  def validate_click
    return if currency_disabled?
    return if offer_disabled?
    return if offer_completed?
    
    wr_path = params[:source] == 'featured' ? 'featured_offer_click' : 'offer_click'
    build_web_request(wr_path)
  end
  
  def currency_disabled?
    disabled = !@currency.tapjoy_enabled?
    if disabled
      build_web_request('disabled_currency')
      save_web_request
      @destination_url = get_destination_url
      render_unavailable_offer
    end
    disabled
  end
  
  def offer_disabled?
    disabled = !@offer.accepting_clicks?
    if disabled
      build_web_request('disabled_offer')
      save_web_request
      @destination_url = get_destination_url
      render_unavailable_offer
    end
    disabled
  end
  
  def offer_completed?
    return false if @offer.multi_complete? && !@offer.frequency_capping_reject?(@device)
    
    app_id_for_device = params[:advertiser_app_id]
    if @offer.item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(params[:advertiser_app_id], params[:app_version])
    end
    
    completed = @device.has_app(app_id_for_device)
    unless completed
      publisher_user = PublisherUser.new(:key => "#{params[:publisher_app_id]}.#{params[:publisher_user_id]}")
      other_udids = publisher_user.udids - [ @device.key ]
      other_udids.each do |udid|
        device = Device.new(:key => udid)
        if device.has_app(app_id_for_device)
          completed = true 
          break
        end
      end
    end
    
    if completed
      build_web_request('completed_offer')
      save_web_request
      @destination_url = get_destination_url
      render_unavailable_offer
    end
    completed
  end
  
  def build_web_request(path)
    @web_request = WebRequest.new(:time => @now)
    @web_request.put_values(path, params, get_ip_address, get_geoip_data, request.headers['User-Agent'])
    @web_request.viewed_at = Time.zone.at(params[:viewed_at].to_f) if params[:viewed_at].present?
  end
  
  def save_web_request
    @web_request.click_key = @click.key if @click.present?
    @web_request.save
  end
  
  def create_click(type)
    @click = Click.new(:key => (type == 'generic' ? UUIDTools::UUID.random_create.to_s : "#{params[:udid]}.#{params[:advertiser_app_id]}"))
    @click.clicked_at        = @now
    @click.viewed_at         = Time.zone.at(params[:viewed_at].to_f)
    @click.udid              = params[:udid]
    @click.publisher_app_id  = params[:publisher_app_id]
    @click.publisher_user_id = params[:publisher_user_id]
    @click.advertiser_app_id = params[:advertiser_app_id]
    @click.displayer_app_id  = params[:displayer_app_id] || ''
    @click.offer_id          = params[:offer_id]
    @click.currency_id       = params[:currency_id]
    @click.reward_key        = UUIDTools::UUID.random_create.to_s
    @click.reward_key_2      = @displayer_app.present? ? UUIDTools::UUID.random_create.to_s : ''
    @click.source            = params[:source] || ''
    @click.ip_address        = get_ip_address
    @click.country           = params[:country_code] || ''
    @click.type              = type
    @click.advertiser_amount = @currency.get_advertiser_amount(@offer)
    @click.publisher_amount  = @currency.get_publisher_amount(@offer, @displayer_app)
    @click.currency_reward   = @currency.get_reward_amount(@offer)
    @click.displayer_amount  = @currency.get_displayer_amount(@offer, @displayer_app)
    @click.tapjoy_amount     = @currency.get_tapjoy_amount(@offer, @displayer_app)
    @click.exp               = params[:exp]
    @click.device_name       = params[:device_name]

    @click.save
  end
  
  def handle_pay_per_click
    if @offer.pay_per_click?
      app_id_for_device = params[:advertiser_app_id]
      if @offer.item_type == 'RatingOffer'
        app_id_for_device = RatingOffer.get_id_with_app_version(params[:advertiser_app_id], params[:app_version])
      end
      @device.set_last_run_time!(app_id_for_device)
      
      message = { :click => @click.serialize(:attributes_only => true), :install_timestamp => @now.to_f.to_s }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end
  end
  
  def get_destination_url
    @offer.destination_url({
      :udid                  => params[:udid],
      :publisher_app_id      => params[:publisher_app_id],
      :currency              => @currency,
      :click_key             => (@click && @click.key),
      :language_code         => params[:language_code],
      :itunes_link_affiliate => @itunes_link_affiliate,
      :display_multiplier    => params[:display_multiplier],
    })
  end
  
  def render_unavailable_offer
    render 'unavailable_offer', :status => 403
  end
  
end
