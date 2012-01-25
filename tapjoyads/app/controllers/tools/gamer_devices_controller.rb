class Tools::GamerDevicesController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def create
    @gamer_device = GamerDevice.new(params[:gamer_device])

    if @gamer_device.save
      redirect_to tools_gamer_path(@gamer_device.gamer), :notice => 'Gamer Device was successfully created and linked.'
    else
      render :action => "new"
    end
  end

  def edit
    @gamer_device = GamerDevice.find(params[:id])
  end

  def new
    if params[:gamer_id].blank?
      redirect_to tools_gamers_path, :alert => 'A gamer ID is required in order to link a new gamer device.'
    else
      @gamer_device = GamerDevice.new(:gamer_id => params[:gamer_id])
    end
  end

  def update
    @gamer_device = GamerDevice.find(params[:id])

    if @gamer_device.update_attributes(params[:gamer_device])
      redirect_to tools_gamer_path(@gamer_device.gamer), :notice => 'Device updated.'
    else
      render :action => "edit"
    end
  end
end
