class RateAppOfferController < ApplicationController
  include RightAws
  include RewardHelper
  
  def index
    
    if request.headers['User-Agent'] && request.headers['User-Agent'].downcase =~ /safari/ && request.headers['User-Agent'].downcase =~ /mobile/ 
      record_id = params[:record_id]
      udid = params[:udid]
      app_id = params[:app_id]
      
      app = App.new(app_id)
      
      rate = RateApp.new("#{app_id}.#{udid}")
      if rate.get('rate-date')
        redirect_to app.get('store_url') 
        return
      end
      
      rate.put('rate-date', Time.now.utc.to_f.to_s)
      rate.save
      
      currency = Currency.new(app_id)
    
      values = calculate_offer_payouts(:currency => currency, :offer_amount => 15)
    
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

      redirect_to app.get('store_url')
      return
    end
  end
end
