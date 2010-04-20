class GetAppImageController < ApplicationController
  include MemcachedHelper
  
  def icon
    return unless verify_params([:app_id])
    
    app_id = params[:app_id].downcase
    app = SdbApp.new(:key => app_id, :load => false)

    if params[:img] == '1'
      redirect_to app.get_icon_url
    else
      image = get_from_cache_and_save("icon.s3.#{app_id.hash}") do
        bucket = RightAws::S3.new.bucket('app_data')
        image_content = bucket.get("icons/#{app_id}.png")
        Base64.encode64 image_content
      end
    
      @icon = image
    end
  end
end
