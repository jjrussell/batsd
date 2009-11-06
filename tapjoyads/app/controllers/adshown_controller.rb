require 'activemessaging/processor'

class AdshownController < ApplicationController
  include ActiveMessaging::MessageSender
  
  verify :params => [:campaign_id, :udid, :app_id],
         :render => {:text => "missing required params"}
  
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END
    
    #message = QueueMessage.serialize([params[:campaign_id], params[:app_id], params[:udid],
    #    Time.now.to_f.to_s])
    
    web_request = WebRequest.new('adshown')
    web_request.put('campaign_id', params[:campaign_id])
    web_request.put('app_id', params[:app_id])
    web_request.put('udid', params[:udid])
    web_request.save
    
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
end