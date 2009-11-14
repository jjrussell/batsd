require 'activemessaging/processor'

##
# Represents a single web request.
class WebRequest < SimpledbResource
  include ActiveMessaging::MessageSender
  
  def initialize(path, domain_name=nil, key=nil)
    now = Time.now.utc
    date = now.iso8601[0,10]
    
    key = UUIDTools::UUID.random_create.to_s unless key
    domain_name = "web-request-#{date}" unless domain_name
    
    super domain_name, key, false
    
    put('path', path)
    put('time', now.to_f.to_s)
  end
  
  def save
    begin
      super false
    rescue => e
      Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"
      publish :web_request, self.serialize
    end
  end
  
  ##
  # Stores the item key and attributes to a json string.
  def serialize
    domain_name = @domain.name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
    {:domain => domain_name, :key => @item.key, :attrs => @item.attributes.to_a}.to_json
  end
  
  ##
  # Re-creates this item from a json string.
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    attributes = json['attrs']
    domain_name = json['domain']
    
    web_request = WebRequest.new('', domain_name, key)

    attributes.each do |pair|
      web_request.put(pair[0], pair[1])
    end
    
    return web_request
  end
end