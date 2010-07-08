class Job::SendMoneyTxnController < Job::SqsReaderController
  include DownloadContent
  
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
        
        raise "No amounts set for reward: #{reward.key}"
      end
      
      conversion = Conversion.new do |c|
        c.id = reward.key
        c.reward_id = reward.key
        c.advertiser_offer_id = reward.get('advertiser_app_id')
        c.publisher_app_id = reward.get('publisher_app_id')
        c.advertiser_amount = reward.get('advertiser_amount')
        c.publisher_amount = reward.get('publisher_amount')
        c.tapjoy_amount = reward.get('tapjoy_amount')
        c.reward_type_string = reward.get('type')
      end
      begin
        conversion.save!
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
        if conversion.errors[:id] == 'has already been taken' || e.message =~ /Duplicate entry.*index_conversions_on_id/
          Rails.logger.info "Duplicate Conversion: #{e.class} when saving conversion: '#{conversion.id}'"
          return
        else
          raise e
        end
      end
      
      reward.put('sent_money_txn', Time.now.utc.to_f.to_s)
      reward.save
      
    end
  end
end
