# TODO: Write tests (include mocks for API calls)
require 'openssl'
require 'xmlrpc/client'

require 'hominid/campaign'
require 'hominid/list'
require 'hominid/security'

module Hominid
  class API
    # Blank Slate
    instance_methods.each do |m|
      undef_method m unless m.to_s =~ /^__|object_id|method_missing|respond_to?|to_s|inspect/
    end
    
    include Hominid::Campaign
    include Hominid::List
    include Hominid::Security
    
    # MailChimp API Documentation: http://www.mailchimp.com/api/1.3/
    MAILCHIMP_API_VERSION = "1.3"

    # Initialize with an API key and config options
    def initialize(api_key, config = {})
      raise ArgumentError.new('Your Mailchimp API key appears to be malformed') unless api_key.include?('-')
      dc = api_key.split('-').last
      defaults = {
        :api_version        => MAILCHIMP_API_VERSION,
        :secure             => false,
        :timeout            => nil
      }
      @config = defaults.merge(config).freeze
      protocol = @config[:secure] ? 'https' : 'http'
      @api_key = api_key
      @chimpApi = XMLRPC::Client.new2("#{protocol}://#{dc}.api.mailchimp.com/#{@config[:api_version]}/", nil, @config[:timeout])
    end

    def method_missing(api_method, *args) # :nodoc:
      @chimpApi.call(api_method.to_s.camelize_api_method_name, @api_key, *args)
    rescue XMLRPC::FaultException => error
      super if error.faultCode == -32601
      raise APIError.new(error)
    end
    
    def respond_to?(api_method)
      @chimpApi.call(api_method, @api_key)
    rescue XMLRPC::FaultException => error
      error.faultCode == -32601 ? false : true 
    end

  end
  
  class APIError < StandardError
    def initialize(error)
      super("<#{error.faultCode}> #{error.message}")
    end
  end

end

class String
  def camelize_api_method_name
    self.to_s[0].chr.downcase + self.gsub(/(?:^|_)(.)/) { $1.upcase }[1..self.size]
  end
end