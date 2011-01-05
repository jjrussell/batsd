class Job::QueueSendCurrencyController < Job::SqsReaderController
  
  def initialize
    super QueueNames::SEND_CURRENCY
  end
  
private
  
  def on_message(message)
    reward = Reward.deserialize(message.to_s)
    return if reward.sent_currency?
    
    currency = Currency.find_in_cache(reward.currency_id)
    publisher_user_id = reward.publisher_user_id
    callback_url = currency.callback_url
    
    if callback_url == 'PLAYDOM_DEFINED'
      first_char = publisher_user_id[0, 1]
      publisher_user_id = publisher_user_id[1..-1]
      
      if first_char == 'F'
        callback_url = 'http://offer-dynamic-lb.playdom.com/tapjoy/mob/facebook/fp/main' # facebook url
      elsif first_char == 'M' || first_char == 'P'
        callback_url = 'http://offer-dynamic-lb.playdom.com/tapjoy/mob/myspace/fp/main' # myspace/iphone url
      else
        Notifier.alert_new_relic(InvalidPlaydomUserId, "Playdom User id: '#{first_char}#{publisher_user_id}' is invalid")
        return
      end
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
    if currency.secret_key.present?
      hash_source = "#{reward.key}:#{publisher_user_id}:#{reward.currency_reward}:#{currency.secret_key}"
      hash = Digest::MD5.hexdigest(hash_source)
      callback_url += "&id=#{reward.key}&verifier=#{hash}"
    end
    
    reward.sent_currency = Time.zone.now
    reward.update_counters
    
    if Rails.env == 'production'
      reward.serial_save(:catch_exceptions => false, :expected_attr => {'sent_currency' => nil})
      
      begin
        if currency.callback_url == 'TAP_POINTS_CURRENCY'
          PointPurchases.transaction(:key => "#{publisher_user_id}.#{reward.publisher_app_id}") do |point_purchases|
            point_purchases.points = point_purchases.points + reward.currency_reward
          end
          reward.send_currency_status = 'OK'
        else
          response = Downloader.get_strict(callback_url, { :timeout => 30 })
          reward.send_currency_status = response.status
        end
      rescue Exception => e
        reward.delete('sent_currency')
        reward.serial_save
        raise e
      end
    end
    
    reward.serial_save
  end
end
