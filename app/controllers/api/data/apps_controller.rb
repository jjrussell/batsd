class Api::Data::AppsController < ApiController
  SAFE_ATTRIBUTES     = [:name, :partner_name, :active_gamer_count, :udid_for_user_id, :primary_app_metadata_id,
                         :active_gamer_count]
  SAFE_ASSOCIATIONS   = {
    :currencies           => Api::Data::CurrenciesController::SAFE_ATTRIBUTES,
    :app_metadatas        => Api::Data::AppMetadataController::SAFE_ATTRIBUTES
  }

  @object_class = App

  before_filter :lookup_object, :sync_object, :only => [:show]

  def show
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES, SAFE_ASSOCIATIONS))
  end
end
