class Api::Data::DevicesController < ApiController

  SAFE_ATTRIBUTES = [:apps, :is_jailbroken, :country, :banned, :product, :version, :mac_address, :publisher_user_ids,
                     :android_id, :platform, :is_papayan, :all_packages, :current_packages,
                     :display_multipliers, :bookmark_tutorial_shown, :suspension_expires_at, :opted_out, :in_network_apps]
  # TODO(isingh): These make RDS calls. Disable them for now
  #:external_publishers, :first_rewardable_currency_id]

  @object_class = Device

  before_filter :lookup_object, :sync_object, :only => [:show, :set_last_run_time, :update]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES))
  end

  def set_last_run_time
    return unless check_params([:app_id])
    render_formatted_response(@object.set_last_run_time!(params[:app_id]), get_object(@object, SAFE_ATTRIBUTES))
  end

  def update
    render_formatted_response(true, get_object(@object, SAFE_ATTRIBUTES))
  end
end
