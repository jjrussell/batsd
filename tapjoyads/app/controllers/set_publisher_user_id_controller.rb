class SetPublisherUserIdController < ApplicationController
  def index
    return unless verify_params([:app_id, :udid, :publisher_user_id])

    device = Device.new(:key => params[:udid])
    device.set_publisher_user_id!(params[:app_id], params[:publisher_user_id])

    render :template => 'layouts/success'
  end
end
