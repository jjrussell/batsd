class ExactTarget
  extend Savon::Model

  ET_TAPJOY_CONSUMER_ACCOUNT_ID = 7001723

  ET_TJM_WELCOME_EMAIL_ID = 'tjm_welcome_en'

  document "https://webservice.s6.exacttarget.com/etframework.wsdl"
  wsse_auth "tapbrian", "welcome@2"

  actions :create, :get_system_status

  def get_system_status
    response = super
    if response.success?
      response.to_array(:system_status_response_msg, :results, :result, :system_status).first
    end
  end

  def send_triggered_email(data)
    data = {
      :account_id     => ExactTarget::ET_TAPJOY_CONSUMER_ACCOUNT_ID,
      :interaction_id => ExactTarget::ET_TJM_WELCOME_EMAIL_ID,
      :subscriber     => "brian.stebar@tapjoy.com",
      :priority       => "High",
      :custom_fields  => {
        :android_device           => 0,
        :confirmation_url         => "https://www.tapjoy.com/confirm?token=CONFIRMATION_TOKEN",
        :currency_id              => "CURRENCY_ID",
        :currency_name            => "GOLD COINS",
        :facebook_signup          => 0,
        :gamer_email              => "gamer_email@tapjoy.com",
        :linked                   => 0,
        :publisher_icon_url       => "https://s3.amazonaws.com/tapjoy/icons/SIZE/ICON_ID.jpg",
        :publisher_app_name       => "PUBLISHER APP NAME",
        :recommendation1_icon_url => "https://s3.amazonaws.com/tapjoy/icons/SIZE/AN_APP.jpg",
        :recommendation1_name     => "An App",
        :recommendation2_icon_url => "https://s3.amazonaws.com/tapjoy/icons/SIZE/ANOTHER_APP.jpg",
        :recommendation2_name     => "Another App",
        :offer1_icon_url          => "https://s3.amazonaws.com/tapjoy/icons/SIZE/AN_OFFER.jpg",
        :offer1_name              => "An Offer",
        :offer1_type              => "App",
        :offer1_amount            => 10,
        :offer2_icon_url          => "https://s3.amazonaws.com/tapjoy/icons/SIZE/ANOTHER_OFFER.jpg",
        :offer2_name              => "Another Offer",
        :offer2_type              => "NotAnApp",
        :offer2_amount            => 20,
        :offer3_icon_url          => "https://s3.amazonaws.com/tapjoy/icons/SIZE/YET_ANOTHER_OFFER.jpg",
        :offer3_name              => "Yet Another Offer",
        :offer3_type              => "App",
        :offer3_amount            => 300,
        :show_detailed_email      => 0,
        :show_offer_data          => 0,
        :show_recommendations     => 0,
      }
    }

    response = client.request :create do
      soap.body = triggered_email_soap_body(data)
    end

    response

    # if response.success?
    #   response.to_array(:create_response, :results)
    # end
  end

  def triggered_email_soap_body(data)
    xml = Builder::XmlMarkup.new
    namespaces = { "xmlns:par" => "http://exacttarget.com/wsdl/partnerAPI" }

    # xml.par :Options do |xml|
    #   xml.par :RequestType, "Asynchronous"
    #   xml.par :QueuePriority, "High"
    # end

    xml.par :Objects, namespaces, "xsi:type" => "par:TriggeredSend" do |xml|
      xml.par :Client do |xml|
        xml.par :ID, data[:account_id]
      end

      xml.par :TriggeredSendDefinition do |xml|
        xml.par :PartnerKey, "xsi:nil" => true
        xml.par :ObjectID, "xsi:nil" => true
        xml.par :CustomerKey, data[:interaction_id]
      end

      xml.par :Subscribers do |xml|
        xml.par :EmailAddress, data[:subscriber]
        xml.par :SubscriberKey, data[:subscriber]

        data[:custom_fields].each do |name,value|
          xml.par :Attributes do |xml|
            xml.par :Name, "#{name.to_s.camelcase}"
            xml.par :Value, "#{value}"
          end
        end
      end
    end
  end
end
