class Api::Data::PartnersController < ApiController
  SAFE_ATTRIBUTES = [:name]

  @object_class = Partner

  before_filter :lookup_object, :sync_object, :only => [:show]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES))
  end
end
