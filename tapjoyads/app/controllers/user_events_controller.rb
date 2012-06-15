class UserEventsController < ApplicationController

  def create
    verify_params([:app_id, :udid, :event_type_id])
    unless params_valid?
      return render :text => UserEvent::ERROR_APP_ID_OR_UDID_MSG , :status => :precondition_failed
    end
    event = UserEvent.new(params)
    if event.valid?
      event.save
      render :text => UserEvent::SUCCESS_MSG, :status => :created
    else
      render :text => UserEvent::ERROR_EVENT_INFO_MSG, :status => :not_acceptable
    end
  end

  private

  def params_valid?
    app           = App.find_by_id(params[:app_id])
    event_type    = UserEvent::EVENT_TYPE_IDS[Integer(params[:event_type_id])] rescue nil
    app.present? && event_type.present?
  end
end
