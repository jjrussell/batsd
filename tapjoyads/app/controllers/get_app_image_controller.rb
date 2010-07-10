class GetAppImageController < ApplicationController
  
  def icon
    return unless verify_params([:app_id])
    
    app_id = params[:app_id].downcase
    
    if params[:img] == '1'
      redirect_to "http://s3.amazonaws.com/app_data/icons/#{app_id}.png" and return
    end
    
    @icon = Mc.get_and_put("icon.s3.#{app_id}") do
      bucket = RightAws::S3.new.bucket('app_data')
      image_content = bucket.get("icons/#{app_id}.png")
      Base64.encode64 image_content
    end
  end
end
