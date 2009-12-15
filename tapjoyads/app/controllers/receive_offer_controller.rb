class ReceiveOfferController < ApplicationController
  include RewardHelper
  include RightAws
  
  def receive_offer
    return record_offer
  end
  
  def cs_receive_offer
    return record_offer(true)
  end
  
  private 
  
  def record_offer(customer_service = nil)
    return unless verify_params([:snuid, :currency])

    snuid = params[:snuid]
    amount = params[:currency]
    
    received_offer = ReceivedOffer.new
    received_offer.put('snuid', snuid)
    received_offer.put('amount', amount)
    
    ##
    # Find the user record by snuid
    user = SimpledbResource.select('publisher-user-record','*', "int_record_id = '#{snuid}'")
    if user.items.length == 0
      received_offer.put('snuid_not_found_error',Time.now.utc.to_f.to_s)
      received_offer.save #save this item so we can look it up later
      raise("Receive offer snuid not found: #{snuid} with received_offer id: #{received_offer.key}")
    end
    
    # use the record to get the publisher_app_id and the publisher_user_id (it's in the key)
    record = user.items.first
    parts = record.key.split('.')
    publisher_app_id = parts[0]
    publisher_user_id = parts[1]    
    currency = Currency.new(publisher_app_id)
    
    values = calculate_offer_payouts(:currency => currency, :offer_amount => amount)
    received_offer.put('advertiser_amount', values[:advertiser_amount])
    received_offer.put('publisher_amount', values[:publisher_amount])
    received_offer.put('currency_reward', values[:currency_reward])
    received_offer.put('tapjoy_amount', values[:tapjoy_amount])
    received_offer.put('offerpal_amount', values[:offerpal_amount])
    
    received_offer.put('customer_service', '1') if customer_service
    
    received_offer.save
    
    #create the reward item and push to the queues
    reward = Reward.new
    reward.put('type', 'offer')
    reward.put('publisher_app_id', publisher_app_id)
    reward.put('cached_offer_id', params[:offerid])
    reward.put('publisher_user_id', publisher_user_id)
    reward.put('advertiser_amount', received_offer.get('advertiser_amount'))
    reward.put('publisher_amount', received_offer.get('publisher_amount'))
    reward.put('currency_reward', received_offer.get('currency_reward'))
    reward.put('tapjoy_amount', received_offer.get('tapjoy_amount'))
    reward.put('offerpal_amount', received_offer.get('offerpal_amount'))
    
    reward.save
    
    message = reward.serialize()
    
    SqsGen2.new.queue(QueueNames::SEND_CURRENCY).send_message(message)
    SqsGen2.new.queue(QueueNames::SEND_MONEY_TXN).send_message(message)



    render :template => 'layouts/success'
  end
end