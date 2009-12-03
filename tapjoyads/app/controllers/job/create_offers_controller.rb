# Gets the list of offers from offerpal

class Job::CreateOffersController < Job::JobController
  include DownloadContent
  
  def index
    
    #first get the list of countries supported by offerpal
    country_list = AWS::S3::S3Object.value 'OfferpalCountryList.txt', 'offer-data'
    countries = country_list.split(/\n/)
    
    next_token = nil
    app_currency_list = []
    while next_token != nil && next_token != ''
      app_items_list = SimpledbResource.select('app','app_id, currency_name, conversion_rate, money_share, banned_offers', 
        "currency_name != ''")
      next_token = app_items_list.next_token
      app_currency_list.push(app_items_list)
    end
    
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
            dbOffer = CachedOffer.new(offerpalID)
            
            dbOffer.put('name', offer['name'])
            dbOffer.put('actionURL', offer['actionURL'])
            dbOffer.put('description', offer['description'])
            dbOffer.put('instructions', offer['instructions'])
            dbOffer.put('imageHTML', offer['imageHTML'])
            dbOffer.put('timeDelay', offer['timeDelay'])
            dbOffer.put('currency', 'TAPJOY_BUCKS')
            dbOffer.put('creditCardRequired', offer['creditCardRequired'])
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
        banned_offers = currency.get('banned_offers').split(';') if currency.get('banned_offers')
        
        xml = "<OfferArray>\n"
        offer_list.each do |offer|
          next if banned.offers.contains offer.key
          return_offer = ReturnOffer.new(0, offer, currency.get('offers_money_share'), currency.get('conversion_rate'))
          xml += return_offer.to_xml
        end
        xml += "</OfferArray>\n"
        
        AWS::S3::S3Object.store "offers_" + currency.get('app_id') + "." + CGI::escape(country), 
          xml, 'offer_lists'
        
      end
      
    end #country loop
    
    render :text => "ok"
  end
end