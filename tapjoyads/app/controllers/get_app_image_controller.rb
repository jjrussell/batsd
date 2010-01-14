class GetAppImageController < ApplicationController
  include MemcachedHelper
  
  def icon
    return unless verify_params([:app_id])
    
    app_id = params[:app_id].downcase
    
    image_name = "#{app_id}"

    if params[:img] == '1'
      image = get_from_cache_and_save("img.icon.s3.#{image_name.hash}") do
        AWS::S3::S3Object.value image_name, 'app-icons'
      end
      
      send_data(image, :type => 'image/png', :filename => "#{app_id}.png", :disposition => 'inline')
    else
      image = get_from_cache_and_save("icon.s3.#{image_name.hash}") do
        image_content = AWS::S3::S3Object.value image_name, 'app-icons'
        Base64.encode64 image_content
      end
    
      @icon = image
    end
  end
end
