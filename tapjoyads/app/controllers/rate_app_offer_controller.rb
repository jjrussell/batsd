class RateAppOfferController < ApplicationController
  include RewardHelper
  include PublisherRecordHelper
  include SqsHelper
  
  layout 'iphone'
  
  def index
    offer = Offer.find_in_cache(params[:app_id])
    rating_offer = RatingOffer.find_in_cache_by_app_id(params[:app_id])
    id_for_device_app_list = rating_offer.get_id_for_device_app_list(params[:app_version])
    device_app_list = DeviceAppList.new(:key => params[:udid])
    
    if device_app_list.has_app(id_for_device_app_list)
      redirect_to(offer.get_destination_url(params[:udid], params[:app_id])) and return
    end
    
    device_app_list.set_app_ran(id_for_device_app_list)
    device_app_list.save
    
    currency = SdbCurrency.new(:key => params[:app_id])
  
    values = calculate_offer_payouts(:currency => currency, :offer_amount => 15)
  
    record_key = lookup_by_int_record(params[:record_id])
    publisher_user_id = record_key.split('.')[1]
    
    #create the reward item and push to the queues
    reward = Reward.new
    reward.put('type', 'rating')
    reward.put('publisher_app_id', params[:app_id])
    reward.put('publisher_user_id', publisher_user_id)
    reward.put('advertiser_amount', '0')
    reward.put('publisher_amount', '0')
    reward.put('currency_reward', values[:currency_reward])
    reward.put('tapjoy_amount', '0')
    reward.put('offerpal_amount', '0')

    reward.save

    web_request = WebRequest.new
    params[:publisher_app_id] = params[:app_id]
    web_request.put_values('rate_app', params, request)
    web_request.save

    message = reward.serialize(:attributes_only => true)

    send_to_sqs(QueueNames::SEND_CURRENCY, message)

    redirect_to offer.get_destination_url(params[:udid], params[:app_id])
  end
end
