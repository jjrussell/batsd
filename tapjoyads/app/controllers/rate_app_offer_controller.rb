class RateAppOfferController < ApplicationController
  layout 'iphone'
  
  def index
    currency = Currency.find_in_cache_by_app_id(params[:app_id])
    rating_offer = RatingOffer.find_in_cache_by_app_id(params[:app_id])
    offer = Offer.find_in_cache(rating_offer.id)
    app = App.find_in_cache(rating_offer.app_id)
    id_for_device_app_list = rating_offer.get_id_for_device_app_list(params[:app_version])
    device_app_list = DeviceAppList.new(:key => params[:udid])
    
    if device_app_list.has_app(id_for_device_app_list)
      redirect_to(app.store_url) and return
    end
    
    device_app_list.set_app_ran(id_for_device_app_list)
    device_app_list.save
    
    #create the reward item and push to the queues
    reward = Reward.new
    reward.put('type', 'rating')
    reward.put('publisher_app_id', params[:app_id])
    reward.put('publisher_user_id', params[:publisher_user_id])
    reward.put('advertiser_amount', '0')
    reward.put('publisher_amount', '0')
    reward.put('currency_reward', currency.get_reward_amount(offer, nil))
    reward.put('tapjoy_amount', '0')

    reward.save

    web_request = WebRequest.new
    params[:publisher_app_id] = params[:app_id]
    web_request.put_values('rate_app', params, get_ip_address, get_geoip_data)
    web_request.save

    message = reward.serialize(:attributes_only => true)

    Sqs.send_message(QueueNames::SEND_CURRENCY, message)

    redirect_to(app.store_url)
  end
end
