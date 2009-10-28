class AdshownController < ApplicationController
  require 'activemessaging/processor'
  
  include ActiveMessaging::MessageSender
  
  publishes_to :hello_world
  
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
  <Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    publish :hello_world, 'Hello World!!!'
    
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
end