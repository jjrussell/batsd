class SetPublisherUserIdController < ApplicationController
  TEXTFREE_PUB_APP_ID = '6b69461a-949a-49ba-b612-94c8e7589642'

  def index
    return unless verify_params([:app_id, :udid, :publisher_user_id])

    device = Device.new(:key => params[:udid])
    device.set_publisher_user_id(params[:app_id], params[:publisher_user_id])

    # Textfree hack. Remove after pinger stops using these app id's.
    device.set_last_run_time(TEXTFREE_PUB_APP_ID) if params[:app_id] == TEXTFREE_PUB_APP_ID && (!device.has_app?(TEXTFREE_PUB_APP_ID) || (Time.zone.now - device.last_run_time(TEXTFREE_PUB_APP_ID)) > 24.hours)

    device.save if device.changed?

    render :template => 'layouts/success'
  end
end
