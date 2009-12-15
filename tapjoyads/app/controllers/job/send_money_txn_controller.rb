class Job::SendMoneyTxnController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::SEND_MONEY_TXN
  end
  
  private
  
  def on_message(message)
    json = JSON.parse(message.to_s)
    publisher_app_id = json['publisher_app_id']
    advertiser_app_id = json['advertiser_app_id']
    reward_id = json['reward_id']
    publisher_amount = json['publisher_amount']
    advertiser_amount = json['advertiser_amount']
    tapjoy_amount = json['tapjoy_amount']
    offerpal_amount = json['offerpal_amount']
    
    
    reward = EarnedReward.new(reward_id)
    unless reward.get('sent_money_txn')
      Rails.logger.info "Sending money transaction to sql: #{reward_id}"

      win_lb = 'http://winweb-lb-1369109554.us-east-1.elb.amazonaws.com/Service1.asmx/'
      url = win_lb + "SubmitMoneyTxn?password=nhytgbvfr" + 
        "&publisher_app_id=#{CGI::escape(publisher_app_id)}" +
        "&advertiser_app_id=#{CGI::escape(advertiser_app_id)}" +
        "&item_id=#{CGI::escape(reward_id)}" +
        "&publisher_amount=#{CGI::escape(publisher_amount)}" +
        "&advertiser_amount=#{CGI::escape(advertiser_amount)}" +
        "&tapjoy_amount=#{CGI::escape(tapjoy_amount)}" +
        "&offerpal_amount=#{CGI::escape(offerpal_amount)}"
        
      
      download_with_retry(url, {:timeout => 15}, {:retries => 3, :alert => true})
      
      reward.put('sent_money_txn', Time.now.utc.to_f.to_s)
      reward.save
      
    end
  end
end