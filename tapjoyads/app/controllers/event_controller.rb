class EventController < ApplicationController

  def new
    return unless params_valid?
  	begin
  	  event = WebRequest.new
  	  event.put_values('event_tracking_request', params, ip_address, geoip_data, request.user_agent)
  	  event.event_type_id = params[:event_type_id]
  	  event.event_data = params[:event_data]
  	  event.save
     	status = 200
  	rescue
  	  status = 500
  	end
   	render :text => 'complete', :status => status
  end

  private

  def params_valid?
  	return false unless verify_params([:app_id, :udid, :publisher_user_id, :timestamp, :event_type_id])
 	  app = App.find_in_cache(params[:app_id])
    return false unless condition_valid?(app.present?, "Invalid app ID.")   # happens when the rescue above gets triggered
    device = Device.new( :key => params[:udid] )
    return false unless condition_valid?(device.present?, "Invalid device UDID.")
    return false unless condition_valid?(device.has_app?(app.id), "This device has never run this app before.")
	  event_type_id = params[:event_type_id]

    ### TODO temporary code follows, will change when publishers can make their own events
    return false unless condition_valid?(event_type_id == '0' || event_type_id == '1', "Unknown event type ID #{event_type_id}.")
    if event_type_id == '0'   #if IAP event
      data = params[:event_data]
      return false unless condition_valid?(data[:name].present?, "IAP: 'Name' must not be blank.")
      return false unless condition_valid?(data[:price].present?, "IAP: 'Price' must not be blank.")
      return false unless condition_valid?(price_valid?(data[:price]), "IAP: 'Price' must be a valid float without any currency symbols.")
      return false unless condition_valid?(data[:currency], "IAP: 'Currency' must not be blank.")
    end
    ### END temporary code
    true
  end

  def price_valid?(price_str)
    # this could be module-ized and used as a general #is_numeric? method
    true if Float(price_str) rescue false
  end

  def condition_valid?(condition, statement)
    return true if condition
    render(:text => statement, :status => 404) and return false
  end

end
