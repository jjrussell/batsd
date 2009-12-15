class Job::QueueSendCurrencyController < Job::SqsReaderController
  include DownloadContent
  
  def initialize
    super QueueNames::SEND_CURRENCY
  end
  
  private
  
  def on_message(message)
    # publisher_user_record_id (key)
    # recieved_offer_id (new table)
    # amount (anount of currency to send)
    # use app_id (from pub_user_record_id) to look up in currency table to award currncy 
    #   ping url
    #   
    # if playdom (look at code)
    # if currency.send_offer (see python code)
    #
    # ping currency_url, add in  snuid=cgi_excape(pub_user_id), and add currency=amount
    #
    # If it returns 403, we're done. Update recieved_offers table with 403
    # If 200 we're done, update ok - never call again.
    # If 500, increment retry counter in recieved_offers table, and add to queue,
    #    or not delete from queue if less than certain number.
    #    If greater than number, mark error in app, and notify newrelic.
    
    json = JSON.parse(message.to_s)
    publisher_user_record_id = json['publisher_user_record_id']
    received_offer_id = json['received_offer_id']
    amount = json['amount']
    publisher_app_name = json['publisher_app_name']
    publisher_currency_given = json['publisher_currency_given']
    
    parts = publisher_user_record_id.split('.')
    advertiser_app_id = parts[0]
    publisher_user_id = parts[1]
    
    currency = Currency.new(app_id)
    
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
    
    callback_url = "#{callback_url}?snuid=#{CGI::escape(publisher_user_id)}&currency=#{amount}"
    
    if currency.get('send_offer') == '1'
      callback_url = "#{callback_url}&application=#{publisher_app_name}&id=#{publisher_app_id}"
    end
    
    secret_key = currency.get('secret_key')
    unless secret_key.nil? or secret_key == 'None'
      hash_source = "#{received_offer_id}:#{publisher_user_id}:#{publisher_currency_given}:#{secret_key}"
      hash = Digest::MD5.hexdigest(hash_source)
      currency_url = "#{currency_url}&id=#{received_offer_id}&verifier=#{hash}"
    end
    
    download_with_retry(callback_url, {:timeout => 15}, 
        {:retries => 10, :alert => true, :fail_action => :mark_app_callback_dead, :app_id => app_id})
  end
end