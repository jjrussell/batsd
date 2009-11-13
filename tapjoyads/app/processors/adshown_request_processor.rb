require 'uuid'

class AdshownRequestProcessor < ApplicationProcessor

  subscribes_to :adshown_request
  
  def on_message(message)
    logger.debug "AdshownRequestProcessor received: " + message
    
    adshown_request = AdshownRequest.new(UUIDTools::UUID.random_create.to_s)
    adshown_request.put('msg', message)
    adshown_request.save
    
    logger.info "AdshownRequest stored. Simpledb box usage: #{adshown_request.box_usage}"
  end
end