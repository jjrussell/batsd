class Api::Data::CurrenciesController < ApiController
  SAFE_ATTRIBUTES = [:name, :conversion_rate, :app_id, :callback_url]

  SAFE_ASSOCIATIONS   = {
    :app => Api::Data::AppsController::SAFE_ATTRIBUTES
  }

  @object_class = Currency

  before_filter :lookup_object, :sync_object, :only => [:show]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES, SAFE_ASSOCIATIONS))
  end
end
