class ClickController < ApplicationController
  
  before_filter :setup
  
  def generic
    return unless verify_params([ :advertiser_app_id, :udid, :publisher_app_id, :publisher_user_id, :offer_id ], { :allow_empty => false })
    
    @offer = Offer.find_in_cache(params[:offer_id])
    return if offer_disabled?
    
    @device_app_list = DeviceAppList.new(:key => params[:udid])
    return if offer_completed?
    
    create_web_request
    create_click('generic', true)
    handle_pay_per_click
    
    if params[:redirect] == '1'
      redirect_to(@offer.get_destination_url(params[:udid], params[:publisher_app_id], nil, nil, @click.key))
    else
      render(:template => 'layouts/success')
    end
  end
  
private
  
  def setup
    @now = Time.zone.now
    
    # Hottest App sends the same publisher_user_record_id for every click
    if params[:publisher_app_id] == '469f7523-3b99-4b42-bcfb-e18d9c3c4576'
      params[:publisher_user_id] = params[:udid]
    end
  end
  
  def offer_disabled?
    disabled = @offer.payment <= 0 || !@offer.tapjoy_enabled
    if disabled
      create_web_request('disabled_offer')
      handle_unavailable_offer
    end
    
    return disabled
  end
  
  def offer_completed?
    completed = @device_app_list.has_app(params[:advertiser_app_id])
    if completed
      create_web_request('completed_offer')
      handle_unavailable_offer
    end
    
    return completed
  end
  
  def handle_unavailable_offer
    if params[:redirect] == '1'
      render(:template => 'click/unavailable_offer', :layout => 'iphone')
    else
      render(:template => 'layouts/success')
    end
  end
  
  def create_web_request(path = 'offer_click')
    web_request = WebRequest.new
    web_request.put_values(path, params, get_ip_address, get_geoip_data)
    web_request.save
  end
  
  def create_click(type, generic = false)
    currency = Currency.find_in_cache_by_app_id(params[:publisher_app_id])
    
    @click = Click.new(:key => (generic ? UUIDTools::UUID.random_create.to_s : "#{params[:udid]}.#{params[:advertiser_app_id]}"))
    @click.clicked_at        = @now
    @click.udid              = params[:udid]
    @click.publisher_app_id  = params[:publisher_app_id]
    @click.publisher_user_id = params[:publisher_user_id]
    @click.advertiser_app_id = params[:advertiser_app_id]
    @click.offer_id          = params[:offer_id]
    @click.reward_key        = UUIDTools::UUID.random_create.to_s
    @click.source            = params[:source]
    @click.country           = get_geoip_data[:country]
    @click.type              = type
    @click.advertiser_amount = currency.get_advertiser_amount(@offer)
    @click.publisher_amount  = currency.get_publisher_amount(@offer)
    @click.currency_reward   = currency.get_reward_amount(@offer)
    @click.tapjoy_amount     = currency.get_tapjoy_amount(@offer)
    @click.save
  end
  
  def handle_pay_per_click
    if @offer.pay_per_click?
      @device_app_list.set_app_ran(params[:advertiser_app_id])
      @device_app_list.save
      
      message = { :click => @click.serialize(:attributes_only => true), :install_timestamp => @now.to_f.to_s }.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)
    end
  end
  
end
