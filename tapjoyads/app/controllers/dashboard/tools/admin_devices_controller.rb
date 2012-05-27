class Dashboard::Tools::AdminDevicesController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
    @admin_devices = AdminDevice.ordered_by_description
  end

  def new
    @admin_device = AdminDevice.new
  end

  def create
    @admin_device = AdminDevice.new(params[:admin_device])
    if @admin_device.save
      flash[:notice] = "Device added"
      device = Device.new(:key => @admin_device.udid)
      device.last_run_time_tester = true
      device.save
      redirect_to tools_admin_devices_path
    else
      render :action => :new
    end
  end

  def edit
    @admin_device = AdminDevice.find(params[:id])
  end

  def update
    @admin_device = AdminDevice.find(params[:id])
    if @admin_device.safe_update_attributes( params[:admin_device], [ :udid, :description, :platform, :user_id ] )
      flash[:notice] = "Device saved"
      redirect_to tools_admin_devices_path
    else
      render :action => :edit
    end
  end

  def destroy
    admin_device = AdminDevice.find(params[:id])
    admin_device.destroy
    device = Device.new(:key => admin_device.udid)
    device.last_run_time_tester = false
    device.save
    flash[:notice] = "Device deleted"
    redirect_to tools_admin_devices_path
  end
end
