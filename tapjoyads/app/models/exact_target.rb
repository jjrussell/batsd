class ExactTarget
  extend Savon::Model

  TJM_WELCOME_EMAIL_ETID = 'tjm_welcome_en'

  document "https://webservice.s6.exacttarget.com/etframework.wsdl"
  wsse_auth "tapbrian", "welcome@2"

  actions :create, :get_system_status

  def get_system_status
    response = super
    if response.success?
      response.to_array(:system_status_response_msg)
    end
  end

  def send_triggered_email

  end

  def soap_body
    xml = Builder::XmlMarkup.new
    namespaces = {  "xmlns:par" => "http://exacttarget.com/wsdl/partnerAPI" }

    xml.par :Objects, namespaces, "xsi:type" => "par:TriggeredSend" do |xml|
      xml.par :Client do |xml|
        xml.par :ID, 7001723
      end

      xml.par :TriggeredSendDefinition do |xml|
        xml.par :PartnerKey, "xsi:nil" => true
        xml.par :ObjectID, "xsi:nil" => true
        xml.par :CustomerKey, "tjm_welcome_en"
      end

      xml.par :Subscribers do |xml|
        xml.par :EmailAddress, "brian.stebar@tapjoy.com"
        xml.par :SubscriberKey, "brian.stebar@tapjoy.com"

        xml.par :Attributes do |xml|
          xml.par :Name, "ConfirmationUrl"
          xml.par :Value, "https://www.tapjoy.com/confirm?token=CONFIRMATION_TOKEN"
        end
        xml.par :Attributes do |xml|
          xml.par :Name, "FacebookSignup"
          xml.par :Value, 1
        end
        xml.par :Attributes do |xml|
          xml.par :Name, "ShowDetailedEmail"
          xml.par :Value, 1
        end
        xml.par :Attributes do |xml|
          xml.par :Name, "Linked"
          xml.par :Value, 1
        end
        xml.par :Attributes do |xml|
          xml.par :Name, "AndroidDevice"
          xml.par :Value, 0
        end
        xml.par :Attributes do |xml|
          xml.par :Name, "ShowOfferData"
          xml.par :Value, 1
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "PublisherIconUrl"
           xml.par :Value, "https://s3.amazonaws.com/tapjoy/icons/SIZE/ICON_ID.jpg"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "PublisherAppName"
           xml.par :Value, "PUBLISHER APP NAME"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "CurrencyId"
           xml.par :Value, "CURRENCY_ID"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "CurrencyName"
           xml.par :Value, "GOLD COINS"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer1IconUrl"
           xml.par :Value, "https://s3.amazonaws.com/tapjoy/icons/SIZE/AN_OFFER.jpg"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer1Name"
           xml.par :Value, "An Offer"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer1Type"
           xml.par :Value, "App"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer1Amount"
           xml.par :Value, 10
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer2IconUrl"
           xml.par :Value, "https://s3.amazonaws.com/tapjoy/icons/SIZE/ANOTHER_OFFER.jpg"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer2Name"
           xml.par :Value, "Another Offer"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer2Type"
           xml.par :Value, "NotAnApp"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer2Amount"
           xml.par :Value, 20
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer3IconUrl"
           xml.par :Value, "https://s3.amazonaws.com/tapjoy/icons/SIZE/YET_ANOTHER_OFFER.jpg"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer3Name"
           xml.par :Value, "Yet Another Offer"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer3Type"
           xml.par :Value, "App"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Offer3Amount"
           xml.par :Value, 300
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "ShowRecommendations"
           xml.par :Value, 1
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Recommendation1IconUrl"
           xml.par :Value, "https://s3.amazonaws.com/tapjoy/icons/SIZE/AN_APP.jpg"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Recommendation1Name"
           xml.par :Value, "An App"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Recommendation2IconUrl"
           xml.par :Value, "https://s3.amazonaws.com/tapjoy/icons/SIZE/ANOTHER_APP.jpg"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "Recommendation2Name"
           xml.par :Value, "Another App"
        end
        xml.par :Attributes do |xml|
           xml.par :Name, "GamerEmail"
           xml.par :Value, "gamer_email@tapjoy.com"
        end
      end
    end

    # <?xml version="1.0" encoding="UTF-8"?>
    # <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    #   <env:Header>
    #     <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
    #       <wsse:UsernameToken wsu:Id="UsernameToken-13" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
    #         <wsse:Username>tapbrian</wsse:Username>
    #         <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">welcome@2</wsse:Password>
    #       </wsse:UsernameToken>
    #     </wsse:Security>
    #   </env:Header>
    #   <env:Body>
    #     <par:CreateRequest xmlns:par="http://exacttarget.com/wsdl/partnerAPI" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    #       <par:Objects xsi:type="par:TriggeredSend">
    #         <par:Client>
    #           <par:ID>7001723</par:ID>
    #         </par:Client>
    #         <par:TriggeredSendDefinition>
    #           <par:PartnerKey xsi:nil="true"/>
    #           <par:ObjectID xsi:nil="true"/>
    #           <par:CustomerKey>tjm_welcome_en</par:CustomerKey>
    #         </par:TriggeredSendDefinition>
    #         <par:Subscribers>
    #           <par:EmailAddress>brian.stebar@tapjoy.com</par:EmailAddress>
    #           <par:Attributes>
    #             <par:Name>html_body</par:Name>
    #             <par:Value>This is my HTML content.</par:Value>
    #           </par:Attributes>
    #           <par:Attributes>
    #             <par:Name>text_body</par:Name>
    #             <par:Value>This is my text content.</par:Value>
    #           </par:Attributes>
    #           <par:SubscriberKey>brian.stebar@tapjoy.com</par:SubscriberKey>
    #         </par:Subscribers>
    #       </par:Objects>
    #     </par:CreateRequest>
    #   </env:Body>
    # </env:Envelope>
  end

end
