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

      currency = Currency.new(:key => reward.get('publisher_app_id'))
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
    
      if callback_url == 'TAP_POINTS_CURRENCY'
        parts = publisher_user_id.split('.')

        if parts.length < 2
          record = PublisherUserRecord.new(:key => "#{reward.get('publisher_app_id')}.#{publisher_user_id}")
          raise "snuid: #{publisher_user_id} not found in publisher-user-record lookup on #{record.key}" if record.get('udid').nil 
          udid = record.get('udid')
          app_id = reward.get('publisher_app_id')
        else
          udid = parts[0]
          app_id = parts[1]
        end

        amount = reward.get('currency_reward')

        begin
          lock_on_key("lock.purchase_vg.#{udid}.#{app_id}") do
            point_purchases = PointPurchases.new(:key => "#{udid}.#{app_id}")

            Rails.logger.info "Adding #{amount} from #{udid}.#{app_id}, to user balance: #{point_purchases.points}"


            point_purchases.points = point_purchases.points + amount.to_i

            point_purchases.serial_save(:catch_exceptions => false)
          end
        rescue KeyExists
          num_retries = num_retries.nil? ? 1 : num_retries + 1
          if num_retries > 3
            raise "Too many retries"
          end
          sleep(0.1)
          retry
        end
      
        reward.put('sent_currency', Time.now.utc.to_f.to_s)
        reward.save

        reward.update_counters
        
        return
      end
      
      mark = '?'
      mark = '&' if callback_url =~ /\?/
      callback_url = "#{callback_url}#{mark}snuid=#{CGI::escape(publisher_user_id)}&currency=#{reward.get('currency_reward')}"
    
      if currency.get('send_offer_data') == '1'
        if (reward.get('type') == 'install')
          adv_app = App.new(:key => reward.get('advertiser_app_id'))
          name = adv_app.get('name')
          id = 'application'
          callback_url += "&storeId=#{CGI::escape(adv_app.get_store_id)}"
        elsif (reward.get('type') == 'offer')
          offer_id = reward.get('cached_offer_id')
          if offer_id
            offer = CachedOffer.new(:key => offer_id)
            id = offer.key
            name = offer.get('name')
          else
            id = 'UNKNOWN'
            name = 'UNKNOWN'
          end
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
        callback_url = "#{callback_url}&id=#{reward.key}&verifier=#{hash}"
      end
    
      reward.put('sent_currency', Time.now.utc.to_f.to_s)
      reward.save
      
      reward.update_counters
    
      download_with_retry(callback_url, {:timeout => 30},
          {:retries => 10, :alert => true, :final_action => 'send_currency_download_complete'}, 
          { :reward_id => reward.key, :app_id => reward.get('publisher_app_id') })
    end
  end
end