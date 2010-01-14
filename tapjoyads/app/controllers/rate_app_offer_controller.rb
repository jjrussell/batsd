class RateAppOfferController < ApplicationController
  include RightAws
  include RewardHelper
  include PublisherRecordHelper
  
  def index
    
    if request.headers['User-Agent'] && request.headers['User-Agent'].downcase =~ /safari/ && request.headers['User-Agent'].downcase =~ /mobile/ 
      record_id = params[:record_id]
      udid = params[:udid]
      app_id = params[:app_id]
      version = ""
      version = ".#{params[:app_version]}" if params[:app_version]
      
      app = App.new(:key => app_id)
      
      rate = RateApp.new(:key => "#{app_id}.#{udid}#{version}")
      if rate.get('rate-date')
        redirect_to app.get('store_url') 
        return
      end
      
      rate.put('rate-date', Time.now.utc.to_f.to_s)
      rate.save
      
      currency = Currency.new(:key => app_id)
    
      values = calculate_offer_payouts(:currency => currency, :offer_amount => 15)
    
      record_key = lookup_by_record(record_id)
      publisher_user_id = record_key.split('.')[1]
      
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

      message = reward.serialize(:attributes_only => true)

      SqsGen2.new.queue(QueueNames::SEND_CURRENCY).send_message(message)

      redirect_to app.get('store_url')
      return
    end
  end
end
