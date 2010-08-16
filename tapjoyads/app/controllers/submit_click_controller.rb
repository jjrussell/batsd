class SubmitClickController < ApplicationController
  
  def store
    # Hottest App sends the same publisher_user_record_id for every click
    if params[:publisher_app_id] == '469f7523-3b99-4b42-bcfb-e18d9c3c4576'
      params[:publisher_user_id] = params[:udid]
    end
    
    return unless verify_params([:advertiser_app_id, :udid, :publisher_app_id, :publisher_user_id], {:allow_empty => false})
    
    now = Time.zone.now
    
    params[:offer_id] = params[:advertiser_app_id] if params[:offer_id].blank?
    offer = Offer.find_in_cache(params[:offer_id])
    
    if offer.get_payment_for_source(params[:source]) <= 0 || !offer.tapjoy_enabled
      @offer = offer
      web_request = WebRequest.new
      web_request.put_values('disabled_offer', params, get_ip_address, get_geoip_data)
      web_request.save
      
      if params[:redirect] == "1"
        render(:template => "submit_click/disabled_offer", :layout => 'iphone') and return
      else
        render(:template => 'layouts/success') and return
      end
    end
    
    if offer.item_type == 'RatingOffer'
      render(:template => 'layouts/success') and return
    end
    
    # don't store the click if the user already has the app installed
    device_app_list = DeviceAppList.new(:key => params[:udid])
    if device_app_list.has_app(params[:advertiser_app_id])
      redirect_to(offer.get_destination_url(params[:udid], params[:publisher_app_id])) and return
    end
    
    currency = Currency.find_in_cache_by_app_id(params[:publisher_app_id])
    
    click = StoreClick.new(:key => "#{params[:udid]}.#{params[:advertiser_app_id]}")
    click.put("click_date", "#{now.to_f.to_s}")
    click.put("publisher_app_id", params[:publisher_app_id])
    click.put("publisher_user_id", params[:publisher_user_id])
    click.put("advertiser_app_id", params[:advertiser_app_id])
    click.put("offer_id", params[:offer_id])
    click.put('advertiser_amount', currency.get_advertiser_amount(offer, params[:source]))
    click.put('publisher_amount', currency.get_publisher_amount(offer, params[:source]))
    click.put('currency_reward', currency.get_reward_amount(offer, params[:source]))
    click.put('tapjoy_amount', currency.get_tapjoy_amount(offer, params[:source]))
    click.put('reward_key', UUIDTools::UUID.random_create.to_s)
    click.put('source', params[:source])
    click.put('country', get_geoip_data[:country])
    click.save
    sharded_click = Click.new(:key => "#{params[:udid]}.#{params[:advertiser_app_id]}")
    sharded_click.clicked_at = now
    sharded_click.publisher_app_id = params[:publisher_app_id]
    sharded_click.publisher_user_id = params[:publisher_user_id]
    sharded_click.advertiser_app_id = params[:advertiser_app_id]
    sharded_click.offer_id = params[:offer_id]
    sharded_click.advertiser_amount = currency.get_advertiser_amount(offer, params[:source])
    sharded_click.publisher_amount = currency.get_publisher_amount(offer, params[:source])
    sharded_click.currency_reward = currency.get_reward_amount(offer, params[:source])
    sharded_click.tapjoy_amount = currency.get_tapjoy_amount(offer, params[:source])
    sharded_click.reward_key = UUIDTools::UUID.random_create.to_s
    sharded_click.source = params[:source]
    sharded_click.country = get_geoip_data[:country]
    sharded_click.save
    
    web_request = WebRequest.new
    web_request.put_values('store_click', params, get_ip_address, get_geoip_data)
    web_request.save
    
    if offer.pay_per_click?
      #assign the currency and consider the txn complete right now
      logger.info "Added fake conversion to sqs queue"
      message = {:udid => params[:udid], :app_id => params[:advertiser_app_id], 
          :install_date => Time.now.utc.to_f.to_s}.to_json
      Sqs.send_message(QueueNames::CONVERSION_TRACKING, message)

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
    return unless verify_params([:app_id, :udid, :offer_id, :publisher_user_id], {:allow_empty => false})
    
    now = Time.now.utc
    
    click = OfferClick.new
    click.put("click_date", "#{now.to_f.to_s}")
    click.put('offer_id', params[:offer_id])
    click.put('app_id', params[:app_id])
    click.put('udid', params[:udid])
    click.put('publisher_user_id', params[:publisher_user_id])
    click.put('source', 'app')
    click.put('ip_address', get_ip_address)
    click.save
    
    publisher_user_record = PublisherUserRecord.new(:key => "#{params[:app_id]}.#{params[:publisher_user_id]}")
    publisher_user_record.update(params[:udid])
    
    web_request = WebRequest.new
    web_request.put_values('offer_click', params, get_ip_address, get_geoip_data)
    web_request.save
    
    render(:template => 'layouts/success')
  end
  
  def ad
    return unless verify_params([:campaign_id, :app_id, :udid])

    web_request = WebRequest.new
    web_request.put_values('adclick', params, get_ip_address, get_geoip_data)
    web_request.save

    render(:template => 'layouts/success')
  end
end
