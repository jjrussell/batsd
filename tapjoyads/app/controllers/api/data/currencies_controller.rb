class Api::Data::CurrenciesController < ApiController
  SAFE_ATTRIBUTES = [:name]

  @is_simpledb = false
  @object_class = Currency

  before_filter :lookup_object, :sync_object, :only => [:show]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES))
  end
end
