class Api::Data::AppMetadataController < ApiController
  SAFE_ATTRIBUTES = [:name, :developer, :thumbs_up, :thumbs_down, :categories, :user_rating, :store_name,
                     :store_id, :file_size_bytes]

  @object_class = AppMetadata

  before_filter :lookup_object, :sync_object, :only => [:show, :increment_or_decrement]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES))
  end

  def increment_or_decrement
    return unless check_params([:attribute_name, :operation_type])
    if params[:operation_type] == "increment"
      @object.increment!(params[:attribute_name].to_sym)
    elsif params[:operation_type] == "decrement"
      @object.decrement!(params[:attribute_name].to_sym)
    end

    render_formatted_response(true, get_object(@object, SAFE_ATTRIBUTES))
  end
end

