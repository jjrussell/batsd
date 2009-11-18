class SubmitClickController < ApplicationController
  
  def store
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject>
<Success>true</Success>
</TapjoyConnectReturnObject>
XML_END

      if ((not params[:advertiser_app_id]) || (not params[:udid]) || (not params[:publisher_app_id]) ||
        (not params[:publisher_user_record_id]) )
        error = Error.new
        error.put('request', request.url)
        error.put('function', 'connect')
        error.put('ip', request.remote_ip)
        error.save
        Rails.logger.info "missing required params"
        render :text => "missing required params"
        return
      end
      
      now = Time.now.utc
      
      ##
      # each attribute that starts with publisher.<id> has a . separated value
      # the left of the . is when the click happened.  the right of the . is the publisher user record
      # so when the app is installed, we look at the timestamp to determine where the reward goes
      click = StoreClick.new("#{params[:udid]}.#{params[:advertiser_app_id]}")
      click.put("click_date", "#{now.to_f.to_s}")
      click.put("publisher_app_id",params[:publisher_app_id])
      click.put("publisher_user_record_id", params[:publisher_user_record_id])
      click.put("advertiser_app_id", params[:advertiser_app_id])
      click.save
      

      respond_to do |f|
        f.xml {render(:text => xml)}
      end
  end
  
end
