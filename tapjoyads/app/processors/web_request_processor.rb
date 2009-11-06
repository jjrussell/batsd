class WebRequestProcessor < ApplicationProcessor
  
  subscribes_to :web_request
  
  def on_message(message)
    web_request = WebRequest.deserialize(message)
    web_request.save
  end
  
end