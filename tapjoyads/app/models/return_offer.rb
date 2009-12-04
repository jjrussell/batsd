class ReturnOffer
  attr_accessor :Cost, :CreditCardRequired, :Currency, :Description, 
    :ImageURL, :Instructions, :Name, :TimeDelay, :CachedOfferID,
    :PublisherUserRecordID, :Type, :EmailURL, :ActionURL, :Amount
    
  def initialize(type, offer, money_share, conversion_rate, currency_name)
    if type == 0 #offers
      @Cost = "Free" 
      @Cost = "Paid" unless offer.get('amount').to_i > 0
      @Currency = currency_name
      @Description = offer.get('description').gsub("TAPJOY_BUCKS", @Currency)
      @Name = offer.get('name').gsub("TAPJOY_BUCKS", @Currency)
      @TimeDelay = offer.get('time_delay')
      @ImageURL = offer.get('image_url')
      @Instructions = offer.get('instructions').gsub("TAPJOY_BUCKS", @Currency)
      @CachedOfferID = offer.get('cached_offer_id')
      @PublisherUserRecordID = "$PUBLISHER_USER_RECORD_ID" #to be replaced
      @ActionURL = offer.get('action_url').gsub('TAPJOY_GENERIC','$INT_IDENTIFIER') #has a TAPJOY_GENERIC to be replaced with INT of publisher_user_record_id
      @Amount = (offer.get('amount').to_f * money_share.to_f * conversion_rate.to_f / 100.0).to_s
      @Type = type
      @EmailURL = "http://www.tapjoyconnect.com/complete_offer?offerid=#{CGI::escape(offer.key)}&udid=$UDID&record_id=$PUBLISHER_USER_RECORD_ID&app_id=$APP_ID&url=#{CGI::escape(@ActionURL)}"
    elsif type == 1 #apps
      @Cost = "Free" 
      @Cost = "Paid" unless offer.get('price').to_i > 0
      @Currency = currency_name
      @Description = offer.get('description')
      @Name = offer.get('name')
      @TimeDelay = 'in seconds'
      @ImageURL = nil
      @Instructions = 'Install and then run the app while online to receive credit.'
      @AppID = offer.get('app_id')
      @PublisherUserRecordID = "$PUBLISHER_USER_RECORD_ID" #to be replaced
      @Amount = (offer.get('payment_for_install').to_f * money_share.to_f * conversion_rate.to_f / 100.0).to_s
      @Type = type
      @EmailURL = nil
      @CachedOfferID = nil
    end
  end  
    
  def to_xml
    
    s = "<OfferReturnClass>\n"
    s += "  <Cost>#{@Cost}</Cost>\n"
    s += "  <CreditCardRequired>#{@CreditCardRequired}</CreditCardRequired>\n"
    s += "  <Currency>#{@Currency}</Currency>\n"
    s += "  <Description>#{@Description}</Description>\n"
    s += "  <ImageURL>#{@ImageURL}</ImageURL>\n"
    s += "  <Instructions>#{@Instructions}</Instructions>\n"
    s += "  <Name>#{@Name}</Name>\n"
    s += "  <TimeDelay>#{@TimeDelay}</TimeDelay>\n"
    s += "  <GameID>#{@AppID}</GameID>\n"
    s += "  <ActionURL>#{@ActionURL}</ActionURL>"
    s += "  <CachedOfferID>#{@CachedOfferID}</CachedOfferID>\n"
    s += "  <PublisherUserRecordID>#{@PublisherUserRecordID}</PublisherUserRecordID>\n"
    s += "  <Type>#{@Type}</Type>\n"
    s += "  <EmailURL>#{@EmailURL}</EmailURL>\n"
    s += "</OfferReturnClass>\n"
    
    return s
    
  end
  
  
end