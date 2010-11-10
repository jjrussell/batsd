class GetAppImageController < ApplicationController
  
  def icon
    return unless verify_params([:app_id])
    
    app_id = params[:app_id].downcase
    
    # Tap Fish sometimes sends malformated params like: app_id=guidimg=1
    if app_id.gsub!('img=1', '') || params[:img] == '1'
      redirect_to "http://content.tapjoy.com/icons/#{app_id}.png" and return
    end
    
    @icon = Mc.get_and_put("icon.s3.#{app_id}") do
      bucket = S3.bucket(BucketNames::APP_DATA)
      image_content = bucket.get("icons/#{app_id}.png")
      Base64.encode64 image_content
    end
  end
end
