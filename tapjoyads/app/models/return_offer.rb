class ReturnOffer
  attr_accessor :Cost, :CreditCardRequired, :Currency, :Description, 
    :ImageURL, :Instructions, :Name, :TimeDelay, :CachedOfferID,
    :PublisherUserRecordID, :Type, :EmailURL, :ActionURL, :Amount
    
  def initialize(type, offer, money_share, conversion_rate, currency_name)
    if type == 0 #offers
      self.Cost = "Free" 
      self.Cost = "Paid" unless offer.attributes['amount'].to_i > 0
      self.Currency = offer.attributes['currency_name']
      self.Description = offer.attributes['description'].gsub("TAPJOY_BUCKS", self.Currency)
      self.Name = offer.attributes['name'].gsub("TAPJOY_BUCKS", self.Currency)
      self.TimeDelay = offer.attributes['time_delay']
      self.ImageURL = offer.attributes['image_url']
      self.Instructions = offer.attributes['instructions'].gsub("TAPJOY_BUCKS", self.Currency)
      self.CachedOfferID = offer.attributes['cached_offer_id']
      self.PublisherUserRecordID = "$PUBLISHER_USER_RECORD_ID" #to be replaced
      self.ActionURL = offer.attributes['action_url'].gsub('TAPJOY_GENERIC','$INT_IDENTIFIER') #has a TAPJOY_GENERIC to be replaced with INT of publisher_user_record_id
      self.Amount = (offer.attributes['amount'].to_f * money_share.to_f * conversion_rate.to_f / 100.0).to_s
      self.Type = type
      self.EmailURL = "http://www.tapjoyconnect.com/complete_offer?offerid=#{CGI::escape(offer.key)}&udid=$UDID&record_id=$PUBLISHER_USER_RECORD_ID&app_id=$APP_ID&url=#{CGI::escape(self.ActionURL)}"
    elsif type == 1 #apps
      self.Cost = "Free" 
      self.Cost = "Paid" unless offer.attributes['price'].to_i > 0
      self.Currency = currency_name
      self.Description = offer.attributes['description'] + offer.attributes['description2'] + offer.attributes['description3']+ offer.attributes['description4']
      self.Name = offer.attributes['name']
      self.TimeDelay = 'in seconds'
      self.ImageURL = nil
      self.Instructions = 'Install and then run the app while online to receive credit.'
      self.AppID = offer.attributes['app_id']
      self.PublisherUserRecordID = "$PUBLISHER_USER_RECORD_ID" #to be replaced
      self.Amount = (offer.attributes['payment_for_install'].to_f * money_share.to_f * conversion_rate.to_f / 100.0).to_s
      self.Type = type
      self.EmailURL = nil
      self.CachedOfferID = nil
    end
  end  
    
  def to_xml
    
    s = "<OfferReturnClass>\n"
    s += "  <Cost>#{self.Cost}</Cost>\n"
    s += "  <CreditCardRequired>#{self.CreditCardRequired}</CreditCardRequired>\n"
    s += "  <Currency>#{self.Currency}</Currency>\n"
    s += "  <Description>#{self.Description}</Description>\n"
    s += "  <ImageURL>#{self.ImageURL}</ImageURL>\n"
    s += "  <Instructions>#{self.Instructions}</Instructions>\n"
    s += "  <Name>#{self.Name}</Name>\n"
    s += "  <TimeDelay>#{self.TimeDelay}</TimeDelay>\n"
    s += "  <GameID>#{self.AppID}</GameID>\n"
    s += "  <ActionURL>#{self.ActionURL}</ActionURL>"
    s += "  <CachedOfferID>#{self.CachedOfferID}</CachedOfferID>\n"
    s += "  <PublisherUserRecordID>#{self.PublisherUserRecordID}</PublisherUserRecordID>\n"
    s += "  <Type>#{self.Type}</Type>\n"
    s += "  <EmailURL>#{self.EmailURL}</EmailURL>\n"
    s += "</OfferReturnClass>\n"
    
    return s
    
  end
  
  
end