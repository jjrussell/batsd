class Job::QueueSendCurrencyController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::SEND_CURRENCY
  end
  
  private
  
  def on_message(message)
    
    reward = Reward.deserialize(message.to_s)
    
    unless reward.get('sent_currency')
      publisher_user_id = reward.get('publisher_user_id')
      unless publisher_user_id
        Rails.logger.info "No publisher_user_id found for reward key: #{reward.key}"
        return
      end

      currency = Currency.find_in_cache_by_app_id(reward.get('publisher_app_id'))
      callback_url = currency.callback_url
    
      if callback_url == 'PLAYDOM_DEFINED'
        first_char = publisher_user_id[0, 1]
        publisher_user_id = publisher_user_id[1, publisher_user_id.length]
      
        callback_url = case first_char
        when 'F'
          'http://offer-dynamic-lb.playdom.com/tapjoy/mob/facebook/fp/main' #facebook url
        when 'M'
          'http://offer-dynamic-lb.playdom.com/tapjoy/mob/myspace/fp/main' #myspace url
        when 'P'
          'http://offer-dynamic-lb.playdom.com/tapjoy/mob/myspace/fp/main' #iphone url
        end
        
      end
    
      if callback_url == 'TAP_POINTS_CURRENCY'
        udid = publisher_user_id
        app_id = reward.get('publisher_app_id')

        amount = reward.get('currency_reward')

        PointPurchases.transaction(:key => "#{udid}.#{app_id}") do |point_purchases|
          point_purchases.points = point_purchases.points + amount.to_i
        end
      
        reward.put('sent_currency', Time.now.utc.to_f.to_s)
        reward.save

        reward.update_counters
        
        return
      end
      
      mark = '?'
      mark = '&' if callback_url =~ /\?/
      callback_url = "#{callback_url}#{mark}snuid=#{CGI::escape(publisher_user_id)}&currency=#{reward.get('currency_reward')}"
    
      if currency.send_offer_data?
        if (reward.get('type') == 'install')
          offer = Offer.find_in_cache(reward.get('advertiser_app_id'))
          name = offer.name
          callback_url += "&storeId=#{CGI::escape(offer.third_party_data)}" if offer.item_type == 'App'
        elsif (reward.get('type') == 'offer')
          offer_id = reward.get('cached_offer_id')
          if offer_id
            offer = CachedOffer.new(:key => offer_id)
            name = offer.get('name')
          else
            name = 'UNKNOWN'
          end
        elsif (reward.get('type') == 'rating')
          name = 'rating'
        end
        callback_url = "#{callback_url}&application=#{CGI::escape(name)}"
        
        publisher_revenue = reward.get('publisher_amount').to_f / 100
        callback_url += "&rev=#{publisher_revenue}"
      end
    
      unless currency.secret_key.blank?
        hash_source = "#{reward.key}:#{publisher_user_id}:#{reward.get('currency_reward')}:#{currency.secret_key}"
        hash = Digest::MD5.hexdigest(hash_source)
        callback_url = "#{callback_url}&id=#{reward.key}&verifier=#{hash}"
      end
    
      reward.put('sent_currency', Time.now.utc.to_f.to_s)
      reward.save
      
      reward.update_counters
    
      download_with_retry(callback_url, {:timeout => 30})
    end
  end
end