# Gets the list of offers from offerpal

class Job::CreateOffersController < Job::SqsReaderController
  include DownloadContent
  include MemcachedHelper
  
  def initialize
    super QueueNames::CREATE_OFFERS
  end
  
  private
  
  def on_message(message)
    
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    
    #first get the list of countries supported by offerpal
    country_list = bucket.get('OfferpalCountryList.txt')
    countries = country_list.split(/\n/)
    
    app_currency_list = []
    
    Currency.select({
        :attributes => 'currency_name, conversion_rate, offers_money_share, disabled_offers',
        :where => "currency_name != ''"}) do |item|
      app_currency_list.push(item)
    end
    
    drop_id = 'b7b401f73d98ff21792b49117edd8b9f'
    
    countries.each do |country|
      next if country != "United States"
      
      offer_hash = {}
      
      for offset in [0,30]
        url = "http://pub.myofferpal.com/#{drop_id}/showoffersAPI.action?snuid=TAPJOY_GENERIC&country=#{CGI::escape(country)}" +
          "&category=iPhone%20Optimized&offset=#{offset}"
        
        begin
          json_string = download_content(url, {:timeout => 30})
          json = JSON.parse(json_string)
          
          json['offerData'].each do |offer|
            offerpal_id = 'UNKNOWN'
            action_url = offer['actionURL']
            
            getpart = action_url.split('?',2)[1]

            pairs = getpart.split('&')
            pairs.each do |pair|
              kv = pair.split('=')
              if kv[0] == 'offerId'
                offerpal_id = kv[1]
              end
            end
            
            next if offerpal_id == 'UNKNOWN'
            next if offer['name'] =~ /Home Depot/
            
            #now we know what the offerpal id is
            cached_offer = CachedOffer.new(:key => offerpal_id.to_s + CGI::escape(country))
            
            cached_offer.put('name', offer['name'], {:cgi_escape => true})
            cached_offer.put('action_url', offer['actionURL'])
            cached_offer.put('description', offer['description'], {:cgi_escape => true})
            cached_offer.put('instructions', offer['instructions'], {:cgi_escape => true})
            cached_offer.put('image_html', offer['imageHTML'])
            cached_offer.put('timeDelay', offer['timeDelay'])
            cached_offer.put('currency', 'TAPJOY_BUCKS')
            cached_offer.put('credit_card_required', offer['creditCardRequired'])
            cached_offer.put('cached_offer_id', UUIDTools::UUID.random_create.to_s) unless cached_offer.get('cached_offer_id')
            
            amount = offer['amount'].to_i
            amount = -1 if amount == 0
            
            cached_offer.put('amount', amount.to_s)
            cached_offer.put('expires', Time.now.utc.to_f.to_s)
            
            cached_offer.save
            
            offer_hash[cached_offer.key] = cached_offer
          end
          
        rescue Exception => e
          Rails.logger.info "Unable to download data from #{url}: #{e}"
        end #begin/rescue
          
      end #offset loop
      
      offer_list = offer_hash.values
      
      offer_list.sort! do |a,b| 
        a.get('ordinal').to_i - b.get('ordinal').to_i
      end
      
      serialized_offer_list = []
      offer_list.each do |offer|
        serialized_offer_list.push(offer.serialize)
      end
      bucket.put('offer_list', serialized_offer_list.to_json)
      save_to_cache('s3.offer-data.offer_list', serialized_offer_list.to_json)
      
    end #country loop
  end
end