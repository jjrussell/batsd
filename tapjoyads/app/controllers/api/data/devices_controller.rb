class Api::Data::DevicesController < ApiController

  SAFE_ATTRIBUTES = [:apps, :is_jailbroken, :country, :banned, :product, :version, :mac_address, :publisher_user_ids,
                     :open_udid, :android_id, :platform, :is_papayan, :all_packages, :current_packages,
                     :display_multipliers, :apple_idfa]

  before_filter :lookup_object, :sync_object, :only => [:show, :set_last_run_time]

  def show
    render_formatted_response(!@object.new_record?, get_simpledb_object(@object, SAFE_ATTRIBUTES))
  end

  def set_last_run_time
    return unless check_params([:app_id])
    render_formatted_response(@object.set_last_run_time!(params[:app_id]), get_simpledb_object(@object, SAFE_ATTRIBUTES))
  end

  private

  def get_object_type
    [Device, true]
  end

end
