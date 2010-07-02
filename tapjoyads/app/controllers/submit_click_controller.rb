class SubmitClickController < ApplicationController
  include ApplicationHelper
  include SqsHelper
  include MemcachedHelper
  
  def store
    
    if params[:publisher_user_id]
      publisher_user_record = PublisherUserRecord.new(
          :key => "#{params[:publisher_app_id]}.#{params[:publisher_user_id]}")
      publisher_user_record.update(params[:udid])
      params[:publisher_user_record_id] = publisher_user_record.get('record_id')
    end
    
    return unless verify_params([:advertiser_app_id, :udid, :publisher_app_id, :publisher_user_record_id])
    
    now = Time.now.utc
    
    offer = Offer.find_in_cache(params[:advertiser_app_id])
    
    if (offer.get_payment_for_source(params[:source]) <= 0 || !offer.tapjoy_enabled) && (params[:redirect] == "1")
      #this app is no longer enabled
      @offer = offer
      web_request = WebRequest.new
      web_request.put_values('disabled_offer', params, request)
      web_request.save
      render(:template => "submit_click/disabled_offer", :layout => 'iphone') and return
    end
    
    if offer.item_type == 'RatingOffer'
      render(:template => 'layouts/success') and return
    end
    
    # don't store the click if the user already has the app installed
    device_app_list = DeviceAppList.new(:key => params[:udid])
    if device_app_list.has_app(params[:advertiser_app_id])
      redirect_to(offer.get_destination_url(params[:udid], params[:publisher_app_id])) and return
    end
    
    ##
    # store how much currency the user earns for this install    
    currency = Currency.find_in_cache_by_app_id(params[:publisher_app_id])
    
    ##
    # each attribute that starts with publisher.<id> has a . separated value
    # the left of the . is when the click happened.  the right of the . is the publisher user record
    # so when the app is installed, we look at the timestamp to determine where the reward goes
    click = StoreClick.new(:key => "#{params[:udid]}.#{params[:advertiser_app_id]}")
    click.put("click_date", "#{now.to_f.to_s}")
    click.put("publisher_app_id", params[:publisher_app_id])
    click.put("publisher_user_record_id", params[:publisher_user_record_id])
    click.put("advertiser_app_id", params[:advertiser_app_id])
    click.put('advertiser_amount', currency.get_advertiser_amount(offer, params[:source]))
    click.put('publisher_amount', currency.get_publisher_amount(offer, params[:source]))
    click.put('currency_reward', currency.get_reward_amount(offer, params[:source]))
    click.put('tapjoy_amount', currency.get_tapjoy_amount(offer, params[:source]))
    click.put('reward_key', UUIDTools::UUID.random_create.to_s)
    click.put('source', params[:source])
    click.save
    
    web_request = WebRequest.new
    web_request.put_values('store_click', params, request)
    web_request.save
    
    if offer.pay_per_click?
      #assign the currency and consider the txn complete right now
      logger.info "Added fake conversion to sqs queue"
      message = {:udid => params[:udid], :app_id => params[:advertiser_app_id], 
          :install_date => Time.now.utc.to_f.to_s}.to_json
      send_to_sqs(QueueNames::CONVERSION_TRACKING, message)

      #record that the user has this app, so we don't show it again
      device_app_list = DeviceAppList.new(:key => params[:udid])
      unless device_app_list.has_app(params[:advertiser_app_id])
        device_app_list.set_app_ran(params[:advertiser_app_id])
        device_app_list.save
      end
    end
    
    if params[:redirect] == "1"
      redirect_to(offer.get_destination_url(params[:udid], params[:publisher_app_id]))
    else
      render(:template => 'layouts/success')
    end
  end
  
  def offer
    return unless verify_params([:app_id, :udid, :offer_id, :publisher_user_record_id])
    
    now = Time.now.utc
    
    click = OfferClick.new
    click.put("click_date", "#{now.to_f.to_s}")
    click.put('offer_id', params[:offer_id])
    click.put('app_id', params[:app_id])
    click.put('udid', params[:udid])
    click.put('record_id', params[:publisher_user_record_id])
    click.put('source', 'app')
    click.put('ip_address', get_ip_address(request))
    click.save
    
    web_request = WebRequest.new
    web_request.put_values('offer_click', params, request)
    web_request.save
    
    render(:template => 'layouts/success')
  end
  
  def ad
    return unless verify_params([:campaign_id, :app_id, :udid])

    web_request = WebRequest.new
    web_request.put_values('adclick', params, request)
    web_request.save

    render(:template => 'layouts/success')
  end
end
