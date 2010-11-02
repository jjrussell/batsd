class Job::QueueSendCurrencyController < Job::SqsReaderController
  
  def initialize
    super QueueNames::SEND_CURRENCY
  end
  
private
  
  def on_message(message)
    
    reward = Reward.deserialize(message.to_s)
    
    unless reward.get('sent_currency')
      publisher_user_id = reward.publisher_user_id
      unless publisher_user_id
        Rails.logger.info "No publisher_user_id found for reward key: #{reward.key}"
        return
      end
      
      # TO CHANGE - always use currency_id 2 days after deploy
      currency = Currency.find_in_cache(reward.currency_id || reward.publisher_app_id)
      callback_url = currency.callback_url
      
      if callback_url == 'PLAYDOM_DEFINED'
        first_char = publisher_user_id[0, 1]
        publisher_user_id = publisher_user_id[1..-1]
        
        if first_char == 'F'
          #facebook url
          callback_url = 'http://offer-dynamic-lb.playdom.com/tapjoy/mob/facebook/fp/main'
        elsif first_char == 'M' || first_char == 'P'
          #myspace/iphone url
          callback_url = 'http://offer-dynamic-lb.playdom.com/tapjoy/mob/myspace/fp/main'
        else
          Notifier.alert_new_relic(InvalidPlaydomUserId, "Playdom User id: '#{first_char}#{publisher_user_id}' is invalid")
          return
        end
      end
      
      if callback_url == 'TAP_POINTS_CURRENCY'
        udid = publisher_user_id
        app_id = reward.publisher_app_id
        
        amount = reward.currency_reward
        
        PointPurchases.transaction(:key => "#{udid}.#{app_id}") do |point_purchases|
          point_purchases.points = point_purchases.points + amount
        end
        
        reward.sent_currency = Time.zone.now
        reward.save
        
        reward.update_counters
        
        return
      end
      
      mark = '?'
      mark = '&' if callback_url =~ /\?/
      callback_url += "#{mark}snuid=#{CGI::escape(publisher_user_id)}&currency=#{reward.currency_reward}"
      
      if currency.send_offer_data?
        offer = Offer.find_in_cache(reward.offer_id)
        callback_url += "&storeId=#{CGI::escape(offer.third_party_data)}" if offer.item_type == 'App' && offer.third_party_data?
        callback_url += "&application=#{CGI::escape(offer.name)}"
        publisher_revenue = reward.publisher_amount / 100.0
        callback_url += "&rev=#{publisher_revenue}"
      end
      
      unless currency.secret_key.blank?
        hash_source = "#{reward.key}:#{publisher_user_id}:#{reward.currency_reward}:#{currency.secret_key}"
        hash = Digest::MD5.hexdigest(hash_source)
        callback_url += "&id=#{reward.key}&verifier=#{hash}"
      end
      
      reward.sent_currency = Time.zone.now
      reward.save
      
      reward.update_counters
      
      failure_message = "reward_key: #{reward.key}, app_id: #{reward.publisher_app_id}"
      Downloader.get_with_retry(callback_url, { :timeout => 30 }, failure_message) if Rails.env == 'production'
    end
  end
end
