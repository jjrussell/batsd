class UserEventsController < ApplicationController

  SUCCESS_MESSAGE = "Successfully saved user event."
  SUCCESS_STATUS  = 200
  ERROR_PARAMS    = "Could not find app or device. Check your app_id and udid paramters.\n"
  ERROR_EVENT     = "Error parsing the event info. For shutdown events, ensure the data field is empty or nonexistent. For IAP events, ensure you provided an item name, a currency name, and a valid float for the price.\n"
  ERROR_STATUS    = 400

  def create
    verify_params([:app_id, :udid, :event_type_id])
    status_msg = ERROR_PARAMS
    if params_valid?
      event = UserEvent.new(params)
      status_msg = ERROR_EVENT
      if event.valid?
        status_msg = SUCCESS_MESSAGE
        event.save
      end
  	end
    if status_msg == SUCCESS_MESSAGE 
      status_code = SUCCESS_STATUS
    else
      status_code = ERROR_STATUS
    end
    render :text => status_msg, :status => status_code and return
  end

  private

  def params_valid?
    app           = App.find(params[:app_id]) rescue nil
    event_type_id = params[:event_type_id].to_i rescue nil
    device        = Device.find(params[:udid]) if app.present? && event_type_id.present?
    device.try(:has_app?, params[:app_id])
  end

end
