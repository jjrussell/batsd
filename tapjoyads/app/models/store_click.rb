require 'activemessaging/processor'

##
# Represents a single click to the app store.
class StoreClick < SimpledbResource
  include ActiveMessaging::MessageSender
  
  def initialize(key)

    
    domain_name = "store-click" unless domain_name
    
    super domain_name, key, true
  end
  
  def save
    begin
      super false
    rescue => e
      Rails.logger.info "Sdb save failed. Adding to sqs. Exception: #{e}"
      publish :store_click, self.serialize
    end
  end
  
  ##
  # Stores the item key and attributes to a json string.
  def serialize
    domain_name = @domain.name.gsub(Regexp.new('^' + RUN_MODE_PREFIX), '')
    {:key => @item.key, :attrs => @item.attributes.to_a}.to_json
  end
  
  ##
  # Re-creates this item from a json string.
  def self.deserialize(str)
    json = JSON.parse(str)
    key = json['key']
    attributes = json['attrs']
    
    store_click = StoreClick.new(key)

    attributes.each do |pair|
      store_click.put(pair[0], pair[1])
    end
    
    return web_request
  end
end