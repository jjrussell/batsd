class RateAppOfferController < ApplicationController
  include RightAws
  include RewardHelper
  
  def index
    
    if request.headers['User-Agent'].downcase =~ /safari/ && request.headers['User-Agent'].downcase =~ /mobile/ 
      record_id = params[:record_id]
      udid = params[:udid]
      app_id = params[:app_id]
    
      app = App.new(app_id)
      
      if app_id == '48707b62-2cda-47c2-85e7-6e7998dd914d'
        currency = Currency.new(app_id)
      
        values = calculate_offer_payouts(:currency => currency, :offer_amount => 10)
      
        ##
        # Find the user record by snuid
        user = SimpledbResource.select('publisher-user-record','*', "record_id = '#{record_id}'")
        if user.items.length == 0
          raise("Install record_id not found: #{record_id} with rate app_id: #{app_id}")
        end
        
        record = user.items.first
        publisher_user_id = record.key.split('.')[1]
        
        #create the reward item and push to the queues
        reward = Reward.new
        reward.put('type', 'rating')
        reward.put('publisher_app_id', app_id)
        reward.put('publisher_user_id', publisher_user_id)
        reward.put('advertiser_amount', '0')
        reward.put('publisher_amount', '0')
        reward.put('currency_reward', values[:currency_reward])
        reward.put('tapjoy_amount', '0')
        reward.put('offerpal_amount', '0')

        reward.save

        message = reward.serialize()

        SqsGen2.new.queue(QueueNames::SEND_CURRENCY).send_message(message)
      else
        
        message = {:udid => udid, :app_id => app_id, 
            :record_id => record_id}.to_json
        SqsGen2.new.queue(QueueNames::RATE_OFFER).send_message(message)
        
      end
      redirect_to app.get('store_url')
      return
    end
  end
end
