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
      flash[:success] = "You've successfully banned #{ban_count} device(s)."
    elsif params[:target_id]
      id_hash[params[:target_id]] = {:date => Time.now.strftime("%m/%d/%y"), :reason => params[:ban_reason]}
      flash[:success] = "You've successfully banned a device." if Utils.ban_devices(id_hash)
    end
    redirect_to tools_device_ban_lists_path
  end

  private

  def setup
    @bucket = S3.bucket(BucketNames::DEVICE_BAN_LIST)
  end
end
