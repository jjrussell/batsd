class SetPublisherUserIdController < ApplicationController
  include AdminDeviceLastRun::ControllerExtensions

  before_filter :reject_banned_udids
  tracks_admin_devices

  def index
    lookup_udid(true)
    return unless verify_params([:app_id, :udid, :publisher_user_id])

    device = Device.new({ :key => params[:udid], :is_temporary => params[:udid_is_temporary].present? })
    device.set_publisher_user_id(params[:app_id], params[:publisher_user_id])
    device.set_display_multiplier(params[:app_id], params[:display_multiplier]) unless params[:display_multiplier].blank?

    # Textfree hack. Remove after pinger stops using these app id's.
    device.set_last_run_time(TEXTFREE_PUB_APP_ID) if params[:app_id] == TEXTFREE_PUB_APP_ID && (!device.has_app?(TEXTFREE_PUB_APP_ID) || (Time.zone.now - device.last_run_time(TEXTFREE_PUB_APP_ID)) > 24.hours)

    device.save if device.changed?

    render :template => 'layouts/success'
  end
end
