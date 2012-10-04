class Api::Data::AppsController < ApiController
  SAFE_ATTRIBUTES     = [:name]
  SAFE_ASSOCIATIONS   = {
    :currencies => Api::Data::CurrenciesController::SAFE_ATTRIBUTES
  }

  @is_simpledb = false
  @object_class = App

  before_filter :lookup_object, :sync_object, :only => [:show]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES, SAFE_ASSOCIATIONS))
  end
end
