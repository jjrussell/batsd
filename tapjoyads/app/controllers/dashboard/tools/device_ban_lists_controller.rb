class Dashboard::Tools::DeviceBanListsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup

  def create
    id_hash = {}
    if params[:file_content].present?
      object = @bucket.objects["#{current_user.id}/#{params[:file_content]}"]
      object.write(:data => params[:file_content].read, :acl => :public_read)
      ban_count = Utils.ban_devices(Utils.create_id_hash(object, params[:ban_reason]))
      object.delete if object.exists?
      flash[:notice] = "You've successfully banned #{ban_count} device(s)."
    elsif params[:target_id].present?
      unless params[:ban_reason].empty?
        id_hash[params[:target_id].strip] = {:date => Time.now.strftime("%m/%d/%y"),
                                             :reason => params[:ban_reason], :action => 'Banned'}
        if Utils.ban_devices(id_hash) > 0
          flash[:notice] = "You've successfully banned a device."
        else
          flash[:error] = "Either the device could not be found or it's already banned."
        end
      else
        raise ArgumentError, "Ban reason cannot be blank."
      end
    end
    redirect_to tools_device_ban_lists_path
  rescue ArgumentError => e
    flash[:error] = e.message
    redirect_to :back
  end

  private

  def setup
    @bucket = S3.bucket(BucketNames::DEVICE_BAN_LIST)
  end
end
