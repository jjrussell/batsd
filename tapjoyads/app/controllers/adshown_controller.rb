class AdshownController < ApplicationController
  require 'activemessaging/processor'
  
  include ActiveMessaging::MessageSender
  
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