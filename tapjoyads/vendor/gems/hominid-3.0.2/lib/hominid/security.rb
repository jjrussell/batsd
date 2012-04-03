module Hominid
  module Security

    # Get a list of all API keys
    def apikeys(username, password, expired = false)
      @chimpApi.call("apikeys", username, password, @api_key, expired)
    end
    
    # Add an API key to your account
    def apikey_add(username, password)
      @chimpApi.call("apikeyAdd", username, password, @api_key)
    end
    
    # Expire a specific API key
    def apikey_expire(username, password, api_key)
      @chimpApi.call("apikeyExpire", username, password, api_key)
    end
    
  end
end