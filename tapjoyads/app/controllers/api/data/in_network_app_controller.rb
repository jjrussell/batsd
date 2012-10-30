class Api::Data::InNetworkAppController < ApiController
  SAFE_ATTRIBUTES = [:in_network_app_metadata, :app_id, :partner_name,
                     :app_name, :currencies, :last_run_time]

  def search
    @object = InNetworkApp.find_by_store_name_and_store_id(params[:store_name], params[:store_key])
    render_formatted_response(!@object.new_record?, get_object(@object, SAFE_ATTRIBUTES))
  end

end
