class ReceiveOfferController < ApplicationController
  include SqsHelper
  
  def receive_offer
    return record_offer
  end
  
  def receive_offer_cs
    return record_offer(true)
  end
  
  private 
  
  def record_offer(customer_service = nil)
    return unless verify_params([:snuid, :currency])
    
    snuid = params[:snuid]
    amount = params[:currency]
    
    # Find the user record by snuid
    record_key = PublisherUserRecord.lookup_key_by_int_record_id(snuid)
    parts = record_key.split('.')
    publisher_app_id = parts[0]
    publisher_user_id = parts[1]
    currency = Currency.find_in_cache_by_app_id(publisher_app_id)
    offer = Offer.new(:item_type => 'OfferpalOffer', :payment => amount)
    
    received_offer = ReceivedOffer.new
    received_offer.put('snuid', snuid)
    received_offer.put('amount', amount)
    received_offer.put('advertiser_amount', currency.get_advertiser_amount(offer, nil))
    received_offer.put('publisher_amount', currency.get_publisher_amount(offer, nil))
    received_offer.put('currency_reward', currency.get_reward_amount(offer, nil))
    received_offer.put('tapjoy_amount', currency.get_tapjoy_amount(offer, nil))
    received_offer.put('customer_service', '1') if customer_service
    received_offer.save
    
    # Create the reward item and push to the queues
    reward = Reward.new
    reward.put('type', 'offer')
    reward.put('publisher_app_id', publisher_app_id)
    reward.put('cached_offer_id', params[:offerid])
    reward.put('publisher_user_id', publisher_user_id)
    reward.put('advertiser_amount', received_offer.get('advertiser_amount'))
    reward.put('publisher_amount', received_offer.get('publisher_amount'))
    reward.put('currency_reward', received_offer.get('currency_reward'))
    reward.put('tapjoy_amount', received_offer.get('tapjoy_amount'))
    reward.save
    
    message = reward.serialize(:attributes_only => true)
    send_to_sqs(QueueNames::SEND_CURRENCY, message)
    send_to_sqs(QueueNames::SEND_MONEY_TXN, message)
    
    web_request = WebRequest.new
    web_request.put_values('receive_offer', params, request)
    web_request.put('publisher_app_id', publisher_app_id)
    web_request.put('offer_id', params[:offerid])
    web_request.save
    
    render :template => 'layouts/success'
  end
end
