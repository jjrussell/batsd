require 'activemessaging/processor'

##
# Represents a single web request.
class WebRequest < SimpledbResource
  include ActiveMessaging::MessageSender
  
  def initialize(path, domain_name=nil, key=nil)
    now = Time.now
    date = now.iso8601[0,10]
    
    key = UUID.new.generate unless key
    domain_name = "web-request-#{date}" unless domain_name
    
    super domain_name, key
    
    put('path', path)
    put('time', now.to_f.to_s)
  end
  
  def save
    begin
      super
    rescue ServerError
      publish :web_request, self.serialize
    end
  end
  
  ##
  # Stores the item key and attributes to a json string.
  def serialize
    {:key => @item.key, :attrs => @item.attributes.to_a}.to_json
  end
  
  ##
  # Re-creates this item from a json string. The domain will be the current day's
  # domain, not the domain it was originally in.
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    attributes = json['attrs']
    
    now = Time.now
    date = now.iso8601[0,10]
    domain_name = "web-request-#{date}"
    
    web_request = WebRequest.new('', domain_name, key)

    attributes.each do |pair|
      web_request.put(pair[0], pair[1])
    end
    
    return web_request
  end
end