class InternalDevicesController < WebsiteController
  filter_access_to :new, :edit, :update, :index, :show, :destroy, :approve

  def new
    if params[:resend]
      @device = current_user.internal_devices.find(params[:device])
      send_email
    elsif params[:device] || device_cookie
      device_id = params[:device] || device_cookie
      @device = current_user.internal_devices.find_by_id(device_id)
    else
      @device = InternalDevice.new
      current_user.internal_devices << @device
      set_cookie( { :value => @device.id, :expires => 1.year.from_now } )
      send_email
    end
  end

  def edit
    @device = InternalDevice.find(params[:id])
  end

  def update
    device = InternalDevice.find(params[:id])
    device.update_attributes(params[:internal_device])
    flash[:notice] = "Device updated! To see the devices and computers you've logged in with <a href=#{internal_device_path(current_user.id)}>click here</a>"
    redirect_to statz_index_path
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
    flash[:notice] = "Device '#{device.description}' removed"
    redirect_to internal_device_path(current_user.id)
  end

  def approve
    @device = InternalDevice.find(params[:id])
    @device.verifier = params[:verifier]
    @device.save
    if @device.approved?
      flash[:notice] = "Device approved!  Please enter a description for this device"
      render :action => :edit
    else
      redirect_bad_device
    end
  end

  def block
    @device = InternalDevice.find(params[:id])
    @device.block!
    @token = params[:token]
    session = UserSession.find
    session.destroy if session
    redirect_to edit_password_reset_url(params[:token])
  end

private

  def send_email
    block_device_url = block_internal_device_url(@device.id, :token => current_user.perishable_token)
    verification_url = approve_internal_device_url(@device.id, :verifier => @device.verification_key)
    geoip_data = get_geoip_data
    location = [ geoip_data[:city], geoip_data[:region], geoip_data[:country] ].compact.join(', ')
    location += " (#{get_ip_address})"
    timestamp = Time.zone.now.strftime("%l:%M%p on %b %d, %Y")
    TapjoyMailer.deliver_approve_device(current_user.email, verification_url, block_device_url, location, timestamp)
  end

end
