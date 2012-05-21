class UserEventsController < ApplicationController

  SUCCESS_MESSAGE = "Successfully saved user event."
  SUCCESS_STATUS  = 200
  ERROR_PARAMS    = "Could not find app or device. Check your app_id and udid paramters."
  ERROR_EVENT     = "Error parsing the event info. For shutdown events, ensure the data field is empty or nonexistent. For IAP events, ensure you provided an item name, a currency name, and a valid float for the price."
  ERROR_STATUS    = 400

  def create
    verify_params([:app_id, :udid, :event_type_id])
    status_msg = ERROR_PARAMS
    if params_valid?
      event = UserEvent.new(params)
      status_msg = ERROR_EVENT
      if event.valid?
        status_msg = SUCCESS
        event.save
      end
  	end
    render :text => status_msg, :status => status_msg == SUCCESS ? SUCCESS_STATUS : ERROR_STATUS
  end

  private

  def params_valid?
    Device.new(:key => params[:udid]).has_app?(params[:app_id])
  end

end
