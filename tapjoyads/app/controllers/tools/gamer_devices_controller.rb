class Tools::GamerDevicesController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def edit
    @gamer_device = GamerDevice.find(params[:id])
  end

  def update
    @gamer_device = GamerDevice.find(params[:id])

    if @gamer_device.update_attributes(params[:gamer_device])
      redirect_to(tools_gamer_path(@gamer_device.gamer), :notice => 'Device updated.')
    else
      render :action => "edit"
    end
  end
end
