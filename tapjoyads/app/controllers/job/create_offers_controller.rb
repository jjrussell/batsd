# Gets the list of offers from offerpal

class Job::CreateOffersController < Job::SqsReaderController
  
  def initialize
    super QueueNames::CREATE_OFFERS
  end
  
private
  
  def on_message(message)
    Offer.find_each(:conditions => "item_type = 'OfferpalOffer'") do |offer|
      offer.user_enabled = false
      offer.save!
    end
    
    drop_id = 'b7b401f73d98ff21792b49117edd8b9f'
    country = 'United States'
    
    [0, 30].each do |offset|
      url = "http://api110.myofferpal.com/#{drop_id}/showoffersAPI.action?snuid=TAPJOY_GENERIC&country=#{CGI::escape(country)}" +
        "&category=iPhone%20Optimized&offset=#{offset}"
      
      json_string = Downloader.get(url, {:timeout => 30})
      json = JSON.parse(json_string)
      
      json['offerData'].each do |offer|
        offerpal_id = 'UNKNOWN'
        action_url = offer['actionURL']
        
        getpart = action_url.split('?', 2)[1]

        pairs = getpart.split('&')
        pairs.each do |pair|
          kv = pair.split('=')
          if kv[0] == 'offerId'
            offerpal_id = kv[1]
          end
        end
        
        next if offerpal_id == 'UNKNOWN'
        next if offer['name'] =~ /Home Depot/
        next unless offer['name'] =~ /Blockbuster|Gamefly|Disney/
        
        amount = offer['amount'].to_i
        amount = -1 if amount == 0
        
        # create the OfferpalOffer
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
        offerpal_offer.primary_offer.update_attribute(:user_enabled, true)
      end
      
    end
    
  end
  
end
