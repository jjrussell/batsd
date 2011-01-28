class GetAppImageController < ApplicationController
  
  def icon
    return unless verify_params([:app_id])
    
    app_id = params[:app_id].downcase
    params[:img] = '1' if app_id.gsub!('img=1', '') # Tap Fish sometimes sends malformated params like: app_id=guidimg=1
    
    offer = Offer.find_in_cache app_id
    return unless verify_records([ offer ])
    icon_id = offer.icon_id
    
    if params[:img] == '1'
      redirect_to "#{CLOUDFRONT_URL}/icons/#{icon_id}.png" and return
    end
    
    @icon = Mc.get_and_put("icon.s3.#{icon_id}", false, 1.day) do
      bucket = S3.bucket(BucketNames::TAPJOY)
      image_content = bucket.get("icons/#{icon_id}.png")
      Base64.encode64 image_content
    end
    
  end
end
