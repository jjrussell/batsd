class Api::Data::PartnersController < ApiController

  SAFE_ATTRIBUTES = [:name]

  @is_simpledb = false
  @object_class = Partner

  before_filter :lookup_object, :sync_object, :only => [:show, :set_last_run_time, :update]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES))
  end
end
