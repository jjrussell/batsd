# Gets the list of offers from offerpal

class Job::CreateOffersController < Job::SqsReaderController
  include DownloadContent
  include MemcachedHelper
  
  def initialize
    super QueueNames::CREATE_OFFERS
  end
  
  private
  
  def on_message(message)
    Offer.connection.execute("UPDATE offers SET user_enabled = false WHERE item_type = 'OfferpalOffer'")
    
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    drop_id = 'b7b401f73d98ff21792b49117edd8b9f'
    country = 'United States'
    
    offer_hash = {}
    
    [0, 30].each do |offset|
      url = "http://api110.myofferpal.com/#{drop_id}/showoffersAPI.action?snuid=TAPJOY_GENERIC&country=#{CGI::escape(country)}" +
        "&category=iPhone%20Optimized&offset=#{offset}"
      
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
        next unless offer['category'] == 'App Installs' || offer['name'] =~ /Blockbuster|Gamefly|Disney|/
        
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
        
        
        # create the mysql OfferpalOffer
        offerpal_offer = OfferpalOffer.find_or_initialize_by_offerpal_id(offerpal_id)
        offerpal_offer.partner_id = "5c0caa42-4be1-4f92-b717-f824b4b2142e"
        offerpal_offer.name = offer['name']
        offerpal_offer.description = offer['description']
        offerpal_offer.url = offer['actionURL']
        offerpal_offer.instructions = offer['instructions']
        offerpal_offer.time_delay = offer['timeDelay']
        offerpal_offer.credit_card_required = offer['creditCardRequired'].to_s == '1'
        offerpal_offer.payment = amount
        offerpal_offer.save!
        offerpal_offer.offer.update_attribute(:user_enabled, true)
      end
      
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
      
  end
end