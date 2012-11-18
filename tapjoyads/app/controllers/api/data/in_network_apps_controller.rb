class Api::Data::InNetworkAppsController < ApiController
  SAFE_ATTRIBUTES = [:in_network_app_metadata, :app_id, :partner_name,
                     :app_name, :currencies, :last_run_time]

  def search
    @object = InNetworkApp.find_by_store_name_and_store_id(params[:search_params][:store_name],
                                                           params[:search_params][:store_id])
    render_formatted_response(true, get_object(@object, SAFE_ATTRIBUTES))
  end

end
