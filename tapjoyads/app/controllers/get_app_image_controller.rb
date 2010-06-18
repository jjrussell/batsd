class GetAppImageController < ApplicationController
  include MemcachedHelper
  
  def icon
    return unless verify_params([:app_id])
    
    app_id = params[:app_id].downcase
    
    if params[:img] == '1'
      redirect_to "http://s3.amazonaws.com/app_data/icons/#{app_id}.png" and return
    end
    
    @icon = get_from_cache_and_save("icon.s3.#{app_id}") do
      bucket = RightAws::S3.new.bucket('app_data')
      image_content = bucket.get("icons/#{app_id}.png")
      Base64.encode64 image_content
    end
  end
end
