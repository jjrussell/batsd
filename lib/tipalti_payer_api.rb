class TipaltiPayerApi

  def initialize
    @client = Savon.client TIPALTI_PAYER_API_WSDL
  end

  def get_dynamic_key(timestamp)
    response = @client.request :tip, :get_dynamic_key do
      soap.body = {
        :payer_name => TIPALTI_PAYER_NAME,
        :timestamp  => timestamp.to_i
      }
      soap.body[:key] = TipaltiPayerApi.generate_encryption_key(soap.body)
    end

    # Scrub API response of unnecessary SOAP crap
    if response.success?
      response.to_array(:get_dynamic_key_response, :get_dynamic_key_result).first
    else
      ##
      ## TODO: Error handling here
      ## The API gave us an HTTP response code of something other than 200
      ##
    end
  end

  def self.generate_encryption_key(values, salt = TIPALTI_ENCRYPTION_SALT)
    # Build key string
    key_string = values.sort.map { |key, value| value }.join

    # Encrypt the key
    OpenSSL::HMAC.hexdigest('sha256', salt, key_string)
  end
end
