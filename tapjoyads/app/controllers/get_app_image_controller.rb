class GetAppImageController < ApplicationController
  
  def icon
    return unless verify_params([:app_id], {:allow_empty => false})
    
    app_id = params[:app_id].downcase
    
    # Tap Fish sometimes sends malformated params like: app_id=guidimg=1
    if app_id.gsub!('img=1', '') || params[:img] == '1'
      redirect_to "http://s3.amazonaws.com/app_data/icons/#{app_id}.png" and return
    end
    
    @icon = Mc.get_and_put("icon.s3.#{app_id}") do
      bucket = RightAws::S3.new.bucket('app_data')
      image_content = bucket.get("icons/#{app_id}.png")
      Base64.encode64 image_content
    end
  end
end
