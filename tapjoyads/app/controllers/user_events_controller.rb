class UserEventsController < ApplicationController

  def create
    verify_params([:app_id, :udid, :event_type_id])
    unless params_valid?
      return render :text => UserEvent::ERROR_APP_ID_OR_UDID_MSG , :status => UserEvent::ERROR_STATUS
    end
    event = UserEvent.new(params)
    if event.valid?
      event.save
      render :text => UserEvent::SUCCESS_MSG, :status => UserEvent::SUCCESS_STATUS
    else
      render :text => UserEvent::ERROR_EVENT_INFO_MSG, :status => UserEvent::ERROR_STATUS
    end
  end

  private

  def params_valid?
    app           = App.find(params[:app_id]) rescue false
    device        = Device.new(:key => params[:udid]) rescue false
    event_type_id = params[:event_type_id] == 1 || params[:event_type_id] == 0    # TODO make useable for all
    binding.pry
    app && device && event_type_id
  end
end
