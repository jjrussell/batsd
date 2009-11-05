require 'activemessaging/processor'

class AdshownController < ApplicationController
  include ActiveMessaging::MessageSender
  
  missing_message = "missing required params"
  verify :params => [:campaign_id, :udid, :app_id],
         :render => {:text => missing_message}
  
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END
    
    message = QueueMessage.serialize([params[:campaign_id], params[:app_id], params[:udid],
        Time.now.to_f.to_s])
    
    #publish :adshown_stats, message
    publish :adshown_request, message
    
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
end