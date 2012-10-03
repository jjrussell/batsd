class Api::Data::FeaturedContentsController < ApiController
  SAFE_ATTRIBUTES = [:tracking_offer, :button_text]

  def load_featured_content
    begin
      device = Device.find(params[:device_id])
      featured_contents = FeaturedContent.with_country_targeting(params[:geoip_data], device, params[:platform])
      @object = featured_contents.weighted_rand(featured_contents.map(&:weight))
      render_formatted_response(true, get_object(@object, SAFE_ATTRIBUTES))
    rescue
      render_formatted_response(false,{})
    end
  end
end


