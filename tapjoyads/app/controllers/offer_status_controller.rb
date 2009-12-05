class OfferStatusController < ApplicationController
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
end