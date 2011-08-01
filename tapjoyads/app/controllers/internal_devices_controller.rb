class InternalDevicesController < WebsiteController
  filter_access_to :all

  def new
    if params[:device].present?
      @device = InternalDevice.find(params[:device])
    else
      @device = InternalDevice.new
      current_user.internal_devices << @device
      cookies["device"] = { :value => @device.id, :expires => 1.year.from_now }
      block_device_url = block_internal_device_url(@device.id)
      password_reset_url = edit_password_reset_url(current_user.perishable_token)
      TapjoyMailer.deliver_approve_device(current_user.email, @device.verification_key, block_device_url, password_reset_url)
    end
  end

  def update
    device = InternalDevice.find(params[:id])
    device.update_attributes(params[:internal_device])
    if device.approved?
      flash[:notice] = "Device approved! To see the devices you've logged in with <a href=#{internal_device_path(current_user.id)}>click here</a>"
      redirect_to statz_index_path
    else
      redirect_bad_device
    end
  end

  def index
    @internal_devices = InternalDevice.approved
  end

  def show
    @internal_devices = current_user.internal_devices.approved
  end

  def destroy
    device = InternalDevice.find(params[:id])
    device.block!
    device.save
    flash[:notice] = "Device #{device.description} removed"
    redirect_to internal_device_path(current_user.id)
  end

  def block
    @device = InternalDevice.find(params[:id])
  end
end
