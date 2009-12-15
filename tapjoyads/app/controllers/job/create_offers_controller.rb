# Gets the list of offers from offerpal

class Job::CreateOffersController < Job::SqsReaderController
  include DownloadContent
  include MemcachedHelper
  
  def initialize
    super QueueNames::CREATE_OFFERS
  end
  
  private
  
  def on_message(message)
    
    #first get the list of countries supported by offerpal
    country_list = AWS::S3::S3Object.value 'OfferpalCountryList.txt', 'offer-data'
    countries = country_list.split(/\n/)
    
    next_token = nil
    app_currency_list = []
    begin
      app_items_list = SimpledbResource.select('currency','currency_name, conversion_rate, offers_money_share, disabled_offers', 
        "currency_name != ''", nil, next_token)
      next_token = app_items_list.next_token
      app_items_list.items.each do |item|
        app_currency_list.push(item)
      end
    end while next_token != nil
    
    drop_id = 'b7b401f73d98ff21792b49117edd8b9f'
    
    countries.each do |country|
      next if country != "United States"
      
      offer_list = []
      
      for offset in [0,30]
        url = "http://pub.myofferpal.com/#{drop_id}/showoffersAPI.action?snuid=TAPJOY_GENERIC&country=#{CGI::escape(country)}" +
          "&category=iPhone%20Optimized&offset=#{offset}"
        
        
        begin
          json_string = download_content(url, {:timeout => 30})
          json = JSON.parse(json_string)
          
          json['offerData'].each do |offer|
            offerpalID = 'UNKNOWN'
            actionURL = offer['actionURL']
            puts actionURL
            
            getpart = actionURL.split('?',2)[1]

            pairs = getpart.split('&')
            pairs.each do |pair|
              kv = pair.split('=')
              if kv[0] == 'offerId'
                offerpalID = kv[1]
              end
            end
            
            puts "#{offer['name']} => #{offerpalID}"
            
            next if offerpalID == 'UNKNOWN'
            
            #now we know what the offerpal id is
            dbOffer = CachedOffer.new(offerpalID.to_s + CGI::escape(country))
            
            dbOffer.put('name', offer['name'])
            dbOffer.put('action_url', offer['actionURL'])
            dbOffer.put('description', offer['description'])
            dbOffer.put('instructions', offer['instructions'])
            dbOffer.put('image_html', offer['imageHTML'])
            dbOffer.put('timeDelay', offer['timeDelay'])
            dbOffer.put('currency', 'TAPJOY_BUCKS')
            dbOffer.put('credit_card_required', offer['creditCardRequired'])
            dbOffer.put('cached_offer_id', UUIDTools::UUID.random_create.to_s) unless dbOffer.get('cached_offer_id')
            
            amount = offer['amount'].to_i
            amount = -1 if amount == 0
            
            dbOffer.put('amount', amount.to_s)
            dbOffer.put('expires',Time.now.utc.to_f.to_s)
            
            dbOffer.save
            
            offer_list.push(dbOffer)
            
          end
          
        rescue Exception => e
          Rails.logger.info "Unable to download data from #{url}: #{e}"
        end #begin/rescue
          
      end #offset loop
      
      #go through and create app-specific lists for each app
      app_currency_list.each do |currency|
        banned_offers = currency.get('disabled_offers').split(';') if currency.get('disabled_offers')
        
        xml = "<OfferArray>\n"
        offer_list.each do |offer|
          next if (banned_offers) && (banned_offers.include? offer.key)
          return_offer = ReturnOffer.new(0, offer, currency)
          xml += return_offer.to_xml
        end
        xml += "</OfferArray>\n"
        
        AWS::S3::S3Object.store "offers_" + currency.key + "." + CGI::escape(country), 
          xml, RUN_MODE_PREFIX + 'offer-data'
        save_to_cache("offers.s3.#{currency.key}.#{CGI::escape(country)}", xml)
      end
      
    end #country loop
    
  end
end