class Job::SendMoneyTxnController < Job::SqsReaderController
  include DownloadContent
  include RewardHelper
  
  def initialize
    super QueueNames::SEND_MONEY_TXN
  end
  
  private
  
  def on_message(message)
    reward = Reward.deserialize(message.to_s)
    
    unless reward.get('sent_money_txn')
      Rails.logger.info "Sending money transaction to sql: #{reward.key}"

      unless reward.get('publisher_amount')
        if reward.get('advertiser_app_id').nil?
          return
        end
        
        values = calculate_install_payouts(
            :currency => Currency.new(:key => reward.get('publisher_app_id')), 
            :advertiser_app => App.new(:key => reward.get('advertiser_app_id')))

        reward.put('advertiser_amount', values[:advertiser_amount])
        reward.put('publisher_amount', values[:publisher_amount])
        reward.put('currency_reward', values[:currency_reward])
        reward.put('tapjoy_amount', values[:tapjoy_amount])
        reward.put('offerpal_amount', values[:offerpal_amount])
      end
      
      conversion = Conversion.new do |c|
        c.reward_id = reward.key
        c.advertiser_app_id = reward.get('advertiser_app_id')
        c.publisher_app_id = reward.get('publisher_app_id')
        c.advertiser_amount = reward.get('advertiser_amount')
        c.publisher_amount = reward.get('publisher_amount')
        c.tapjoy_amount = reward.get('tapjoy_amount').to_i + reward.get('offerpal_amount').to_i
        c.reward_type_string = reward.get('type')
      end
      conversion.save!
      
      #win_lb = 'http://www.tapjoyconnect.com.asp1-3.dfw1-1.websitetestlink.com/Service1.asmx/'
      win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/Service1.asmx/'
      url = win_lb + "SubmitMoneyTxn?password=asfyrexvlkjewr214314" + 
        "&publisher_app_id=#{CGI::escape(reward.get('publisher_app_id'))}" +
        "&advertiser_app_id=#{CGI::escape(reward.get('advertiser_app_id') || '')}" +
        "&item_id=#{CGI::escape(reward.key)}" +
        "&publisher_amount=#{CGI::escape(reward.get('publisher_amount'))}" +
        "&advertiser_amount=#{CGI::escape(reward.get('advertiser_amount'))}" +
        "&tapjoy_amount=#{CGI::escape(reward.get('tapjoy_amount'))}" +
        "&offerpal_amount=#{CGI::escape(reward.get('offerpal_amount'))}" +
        "&money_txn_id=#{conversion.id}"
      
      download_with_retry(url, {:timeout => 30}, {:retries => 3, :alert => true})
      
      reward.put('sent_money_txn', Time.now.utc.to_f.to_s)
      reward.save
      
    end
  end
end