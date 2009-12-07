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
      @ActionURL = offer.get('action_url').gsub(" ","%20").gsub('TAPJOY_GENERIC','INT_IDENTIFIER') #has a TAPJOY_GENERIC to be replaced with INT of publisher_user_record_id
      puts @ActionURL
      STDOUT.flush
      @Amount = (offer.get('amount').to_f * money_share.to_f * conversion_rate.to_f / 100.0).to_i.to_s
      @Type = type
      @EmailURL = "http://www.tapjoyconnect.com/complete_offer?offerid=#{CGI::escape(offer.key)}&udid=$UDID&record_id=$PUBLISHER_USER_RECORD_ID&app_id=$APP_ID&url=#{CGI::escape(CGI::escape(@ActionURL))}"
    elsif type == 1 #apps
      @Cost = "Free" 
      @Cost = "Paid" if offer.get('price') && offer.get('price').to_i > 0
      @Currency = currency_name
      @Description = offer.get('description')
      @Name = offer.get('name')
      @Amount = (offer.get('payment_for_install').to_f * money_share.to_f * conversion_rate.to_f / 100.0).to_i.to_s
      @TimeDelay = 'in seconds'
      @ImageURL = nil
      @Instructions = 'Install and then run the app while online to receive credit.'
      @ActionURL = offer.get('store_url')
      @AdvertiserAppID = offer.key
      @PublisherUserRecordID = "$PUBLISHER_USER_RECORD_ID" #to be replaced
      @Type = type
      @EmailURL = nil
      @CachedOfferID = nil
      @CreditCardRequired = "false"
    end
  end  

  def to_xml
    
    s = "<OfferReturnClass>\n"
    s += "  <Cost>#{CGI::escapeHTML(@Cost)}</Cost>\n" if @Cost
    s += "  <Amount>#{@Amount}</Amount>"
    s += "  <CreditCardRequired>#{CGI::escapeHTML(@CreditCardRequired)}</CreditCardRequired>\n" if @CreditCardRequired
    s += "  <Currency>#{CGI::escapeHTML(@Currency)}</Currency>\n" if @Currency
    s += "  <Description>#{CGI::escapeHTML(@Description)}</Description>\n" if @Description
    s += "  <ImageURL>#{CGI::escapeHTML(@ImageURL)}</ImageURL>\n" if @ImageURL
    s += "  <Instructions>#{CGI::escapeHTML(@Instructions)}</Instructions>\n" if @Instructions
    s += "  <Name>#{CGI::escapeHTML(@Name)}</Name>\n" if @Name
    s += "  <TimeDelay>#{CGI::escapeHTML(@TimeDelay)}</TimeDelay>\n" if @TimeDelay
    s += "  <AdvertiserAppID>#{CGI::escapeHTML(@AdvertiserAppID)}</AdvertiserAppID>\n" if @AdvertiserAppID
    s += "  <ActionURL>#{CGI::escapeHTML(@ActionURL)}</ActionURL>\n" if @ActionURL
    s += "  <CachedOfferID>#{CGI::escapeHTML(@CachedOfferID)}</CachedOfferID>\n" if @CachedOfferID
    s += "  <PublisherUserRecordID>#{CGI::escapeHTML(@PublisherUserRecordID)}</PublisherUserRecordID>\n" if @PublisherUserRecordID
    s += "  <Type>#{@Type}</Type>\n"
    s += "  <EmailURL>#{CGI::escapeHTML(@EmailURL)}</EmailURL>\n" if @EmailURL
    s += "</OfferReturnClass>\n"
    
    return s
    
  end
  
  
end