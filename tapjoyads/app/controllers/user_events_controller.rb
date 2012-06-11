class UserEventsController < ApplicationController

  def create
    verify_params([:app_id, :udid, :event_type_id])
    unless params_valid?
      return render :text =>  "Could not find app or device. Check your app_id and udid paramters.\n", :status => 400
    end
    event = UserEvent.new(params)
    if event.valid?
      event.save
      render :text => "Successfully saved user event.", :status => 200
    else
      render :text => "Error parsing the event info. For shutdown events, ensure the data field is empty or nonexistent. For IAP events, ensure you provided an item name, a currency name, and a valid float for the price.\n", :status => 400
    end
  end

  private

  def params_valid?
    app           = App.find_by_id(params[:app_id])
    event_type_id = params[:event_type_id].to_i rescue nil
    device        = Device.find(params[:udid]) if app.present? && event_type_id.present?
    device.try(:has_app?, params[:app_id])
  end
end
