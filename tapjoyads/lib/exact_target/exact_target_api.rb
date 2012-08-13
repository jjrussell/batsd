class ExactTargetApi
  API_USERNAME = 'tapjoy_apiuser'
  API_PASSWORD = 'welcome@2'
  ##
  ## TODO: Cache WSDL locally for performance reasons (be refresh regularly)
  ##
  API_HOSTNAME = 'https://webservice.s6.exacttarget.com/etframework.wsdl'

  TAPJOY_CONSUMER_ACCOUNT_ID = 7001723

  attr_accessor :client

  def initialize
    @client = Savon.client API_HOSTNAME
    @client.wsse.credentials API_USERNAME, API_PASSWORD
  end

  def get_system_status
    response = @client.request :get_system_status

    # Scrub API response of unnecessary SOAP crap
    if response.success?
      response.to_array(:system_status_response_msg, :results, :result).first
    end
  end

  def send_triggered_email(email_address, interaction_id, data, options)
    ##
    ## TODO: VALIDATE STUFF (like email address)
    ##
    ## Note: ET's List Detective should identify bogus email addresses, so we only need
    ##       to do basic validation
    ##

    response = @client.request :create do
      soap.body = triggered_email_soap_body(email_address, interaction_id, data, options)
    end

    # Scrub API response of unnecessary SOAP crap
    if response.success?
      array = response.to_array(:create_response, :results).first
      array.delete(:"@xsi:type")
      array
    end
  end

  private

  def triggered_email_soap_body(email_address, interaction_id, data, options)
    xml = Builder::XmlMarkup.new
    namespaces = { "xmlns:par" => "http://exacttarget.com/wsdl/partnerAPI" }

    xml.par :Objects, namespaces, "xsi:type" => "par:TriggeredSend" do |xml|
      if options[:account_id].present?
        xml.par :Client do |xml|
          xml.par :ID, options[:account_id]
        end
      end

      xml.par :TriggeredSendDefinition do |xml|
        xml.par :PartnerKey, "xsi:nil" => true
        xml.par :ObjectID, "xsi:nil" => true
        xml.par :CustomerKey, interaction_id
      end

      xml.par :Subscribers do |xml|
        xml.par :EmailAddress, email_address
        xml.par :SubscriberKey, email_address

        data.each do |name,value|
          xml.par :Attributes do |xml|
            xml.par :Name, "#{name.to_s.camelcase}"
            xml.par :Value, "#{value}"
          end
        end
      end
    end
  end
end
