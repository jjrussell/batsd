class Job::SendMoneyTxnController < Job::SqsReaderController
  
  def initialize
    super QueueNames::SEND_MONEY_TXN
  end
  
private
  
  def on_message(message)
    reward = Reward.deserialize(message.to_s)
    
    if reward.sent_money_txn.present?
      return
    end
    
    if reward.publisher_amount.blank?
      raise "No amounts set for reward: #{reward.key}"
    end
    
    conversion = Conversion.new do |c|
      c.id = reward.key
      c.reward_id = reward.key
      c.advertiser_offer_id = reward.offer_id
      c.publisher_app_id = reward.publisher_app_id
      c.advertiser_amount = reward.advertiser_amount
      c.publisher_amount = reward.publisher_amount
      c.tapjoy_amount = reward.tapjoy_amount
      c.reward_type_string = reward.type
      c.created_at = reward.created
    end
    save_conversion(conversion)
    
    if reward.displayer_app_id.present?
      conversion = Conversion.new do |c|
        c.id = reward.reward_key_2
        c.reward_id = reward.key
        c.advertiser_offer_id = reward.offer_id
        c.publisher_app_id = reward.displayer_app_id
        c.advertiser_amount = 0
        c.publisher_amount = reward.displayer_amount
        c.tapjoy_amount = 0
        c.reward_type_string_for_displayer = reward.type
        c.created_at = reward.created
      end
      save_conversion(conversion)
    end
    
    reward.sent_money_txn = Time.zone.now
    reward.save
  end
  
  def save_conversion(conversion)
    begin
      conversion.save!
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      if conversion.errors[:id] == 'has already been taken' || e.message =~ /Duplicate entry.*index_conversions_on_id/
        Rails.logger.info "Duplicate Conversion: #{e.class} when saving conversion: '#{conversion.id}'"
      else
        raise e
      end
    end
  end
  
end
