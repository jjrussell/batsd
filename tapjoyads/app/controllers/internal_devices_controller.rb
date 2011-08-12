class InternalDevicesController < WebsiteController
  filter_access_to :new, :update, :index, :show, :destroy

  def new
    if params[:device].present? || cookies[:device].present?
      device_id = params[:device] || cookies[:device]
      @device = InternalDevice.find(device_id)
    else
      @device = InternalDevice.new
      current_user.internal_devices << @device
      cookies["device"] = { :value => @device.id, :expires => 1.year.from_now }
      block_device_url = block_internal_device_url(@device.id, :token => current_user.perishable_token)
      geoip_data = get_geoip_data
      location = [ geoip_data[:city], geoip_data[:region], geoip_data[:country] ].compact.join(', ')
      location += " (#{get_ip_address})"
      timestamp = Time.zone.now.strftime("%l:%M%p on %b %d, %Y")
      TapjoyMailer.deliver_approve_device(current_user.email, @device.verification_key, block_device_url, location, timestamp)
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
    flash[:notice] = "Device #{device.description} removed"
    redirect_to internal_device_path(current_user.id)
  end

  def block
    @device = InternalDevice.find(params[:id])
    @device.block!
    @token = params[:token]
    session = UserSession.find
    session.destroy if session
    redirect_to edit_password_reset_url(params[:token])
  end
end
