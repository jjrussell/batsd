class Job::QueueSendCurrencyController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::SEND_CURRENCY
  end
  
  private
  
  def on_message(message)
    
    reward = SimpledbResource.deserialize(message.to_s)
    
    unless reward.get('sent_currency')
      publisher_user_id = reward.get('publisher_user_id')
      unless publisher_user_id
        Rails.logger.info "No publisher_user_id found for reward key: #{reward.key}"
        return
      end

      currency = Currency.new(reward.get('publisher_app_id'))
      callback_url = currency.get('callback_url')
    
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
    
      callback_url = "#{callback_url}?snuid=#{CGI::escape(publisher_user_id)}&currency=#{reward.get('currency_reward')}"
    
      if currency.get('send_offer') == '1'
        if (reward.get('type') == 'install')
          adv_app = App.new(reward.get('advertiser_app_id'))
          name = adv_app.get('name')
          id = 'application'
        elsif (reward.get('type') == 'offer')
          offer = CachedOffer.new(reward.get('cached_offer_id'))
          id = offer.key
          name = offer.get('name')
        elsif (reward.get('type') == 'rating')
          id = 'rating'
          name = 'rating'
        end
        callback_url = "#{callback_url}&application=#{CGI::escape(name)}&id=#{CGI::escape(id)}"
      end
    
      secret_key = currency.get('secret_key')
      unless secret_key.nil? or secret_key == 'None'
        hash_source = "#{reward.key}:#{publisher_user_id}:#{reward.get('currency_reward')}:#{secret_key}"
        hash = Digest::MD5.hexdigest(hash_source)
        currency_url = "#{currency_url}&id=#{reward.key}&verifier=#{hash}"
      end
    
      reward.put('sent_currency', Time.now.utc.to_f.to_s)
      reward.save
    
      download_with_retry(callback_url, {:timeout => 15},
          {:retries => 10, :alert => true, :final_action => 'send_currency_download_complete'}, 
          { :reward_id => reward.key, :app_id => reward.get('publisher_app_id') })
    end
  end
end