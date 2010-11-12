class ClickController < ApplicationController
  layout 'iphone'
  
  before_filter :determine_link_affiliates, :only => :app
  before_filter :setup
  
  def app
    @offer = Offer.find_in_cache(params[:offer_id])
    return if offer_disabled?
    
    @device = Device.new(:key => params[:udid])
    return if offer_completed?
    
    create_web_request
    create_click('install')
    handle_pay_per_click
    
    redirect_to(@offer.get_destination_url(params[:udid], params[:publisher_app_id], nil, @itunes_link_affiliate))
  end
  
  def generic
    @offer = Offer.find_in_cache(params[:offer_id])
    return if offer_disabled?
    
    @device = Device.new(:key => params[:udid])
    return if offer_completed?
    
    create_web_request
    create_click('generic')
    handle_pay_per_click
    
    redirect_to(@offer.get_destination_url(params[:udid], params[:publisher_app_id], @click.key))
  end
  
  def rating
    @offer = Offer.find_in_cache(params[:offer_id])
    return if offer_disabled?
    
    @device = Device.new(:key => params[:udid])
    return if offer_completed?
    
    create_web_request
    create_click('rating')
    handle_pay_per_click
    
    redirect_to(@offer.get_destination_url(params[:udid], params[:publisher_app_id], nil, @itunes_link_affiliate))
  end
  
  def test_offer
    @currency = Currency.find_in_cache(params[:currency_id])
    unless @currency.get_test_device_ids.include?(params[:udid])
      raise "not a test device"
    end
    
    test_reward = Reward.new
    test_reward.type              = 'test_offer'
    test_reward.udid              = params[:udid]
    test_reward.publisher_user_id = params[:publisher_user_id]
    test_reward.currency_id       = params[:currency_id]
    test_reward.publisher_app_id  = params[:publisher_app_id]
    test_reward.advertiser_app_id = params[:publisher_app_id]
    test_reward.offer_id          = params[:publisher_app_id]
    test_reward.currency_reward   = 10
    test_reward.publisher_amount  = 0
    test_reward.advertiser_amount = 0
    test_reward.tapjoy_amount     = 0
    
    message = test_reward.serialize
    Sqs.send_message(QueueNames::SEND_CURRENCY, message)
  end
  
private
  
  def setup
    @now = Time.zone.now
    
    # Hottest App sends the same publisher_user_id for every click
    if params[:publisher_app_id] == '469f7523-3b99-4b42-bcfb-e18d9c3c4576'
      params[:publisher_user_id] = params[:udid]
    end
    
    #TO REMOVE: hackey stuff for doodle buddy, remove on Jan 1, 2011
    doodle_buddy_holiday_id = '0f791872-31ec-4b8e-a519-779983a3ea1a'
    doodle_buddy_regular_id = '3cb9aacb-f0e6-4894-90fe-789ea6b8361d'
    params[:publisher_app_id] = doodle_buddy_regular_id if params[:publisher_app_id] == doodle_buddy_holiday_id
    
    verify_params([ :advertiser_app_id, :udid, :publisher_app_id, :publisher_user_id, :offer_id, :currency_id ])
  end
  
  def offer_disabled?
    disabled = !@offer.is_enabled?
    if disabled
      create_web_request('disabled_offer')
      render(:template => 'click/unavailable_offer')
    end
    
    return disabled
  end
  
  def offer_completed?
    app_id_for_device = params[:advertiser_app_id]
    if @offer.item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(params[:advertiser_app_id], params[:app_version])
    end
    completed = @device.has_app(app_id_for_device)
    if completed
      create_web_request('completed_offer')
      render(:template => 'click/unavailable_offer')
    end
    
    return completed
  end
  
  def create_web_request(path = 'offer_click')
    web_request = WebRequest.new
    web_request.put_values(path, params, get_ip_address, get_geoip_data)
    web_request.viewed_at = Time.zone.at(params[:viewed_at].to_f) if params[:viewed_at].present?
    web_request.save
  end
  
  def create_click(type)
    currency = Currency.find_in_cache(params[:currency_id])
    displayer_app = nil
    reward_key_2 = nil
    if params[:displayer_app_id].present?
      displayer_app = App.find_in_cache(params[:displayer_app_id])
      reward_key_2 = UUIDTools::UUID.random_create.to_s
    end
    
    @click = Click.new(:key => (type == 'generic' ? UUIDTools::UUID.random_create.to_s : "#{params[:udid]}.#{params[:advertiser_app_id]}"))
    @click.clicked_at        = @now
    @click.viewed_at         = Time.zone.at(params[:viewed_at].to_f)
    @click.udid              = params[:udid]
    @click.publisher_app_id  = params[:publisher_app_id]
    @click.publisher_user_id = params[:publisher_user_id]
    @click.advertiser_app_id = params[:advertiser_app_id]
    @click.displayer_app_id  = params[:displayer_app_id]
    @click.offer_id          = params[:offer_id]
    @click.currency_id       = params[:currency_id]
    @click.reward_key        = UUIDTools::UUID.random_create.to_s
    @click.reward_key_2      = reward_key_2
    @click.source            = params[:source]
    @click.country           = get_geoip_data[:country]
    @click.type              = type
    @click.advertiser_amount = currency.get_advertiser_amount(@offer)
    @click.publisher_amount  = currency.get_publisher_amount(@offer, displayer_app)
    @click.currency_reward   = currency.get_reward_amount(@offer)
    @click.displayer_amount  = currency.get_displayer_amount(@offer, displayer_app)
    @click.tapjoy_amount     = currency.get_tapjoy_amount(@offer, displayer_app)
    @click.exp               = params[:exp]
    @click.save
  end
  
  def handle_pay_per_click
    if @offer.pay_per_click?
      app_id_for_device = params[:advertiser_app_id]
      if @offer.item_type == 'RatingOffer'
        app_id_for_device = RatingOffer.get_id_with_app_version(params[:advertiser_app_id], params[:app_version])
      end
      @device.set_app_ran(app_id_for_device, params)
      @device.save
      
      message = { :click => @click.serialize(:attributes_only => true), :install_timestamp => @now.to_f.to_s }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end
  end
  
end
