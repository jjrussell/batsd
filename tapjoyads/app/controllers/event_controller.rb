class EventController < ApplicationController

  def new
  	verify_params([:app_id, :udid, :publisher_user_id, :event_type_id, :event_data])
  	event = WebRequest.new
  	event.put_values('event_tracking_request', params, ip_address, geoip_data, user_agent)
  	event.event_type_id = params[:event_type_id]
  	event.event_data = params[:event_data]
  	event.save
  	render :nothing => true, :status => 200 and return
  end

end
