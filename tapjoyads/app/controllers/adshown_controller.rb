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

    publish :hello_world, '4444'
    
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
end