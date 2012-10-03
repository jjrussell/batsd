class Api::Data::RecommendationListsController < ApiController
  SAFE_ATTRIBUTES = [:apps]

  def new
    options = params.slice(:device_id, :device_type, :geoip_data, :os_version)
    begin
      @object = RecommendationList.new(options)
      render_formatted_response(true, get_object(@object, SAFE_ATTRIBUTES))
    rescue
      render_formatted_response(false,{})
    end
  end
end

