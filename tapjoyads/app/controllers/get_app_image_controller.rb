class GetAppImageController < ApplicationController

  def icon
    # For this legacy action, the app_id paramater will actually be the app's hashed_icon_id.
    return unless verify_params([:app_id])

    Rails.logger.info "UserAgent: #{request.headers['User-Agent']}"

    icon_id = params[:app_id].downcase
    params[:img] = '1' if icon_id.gsub!('img=1', '') # Tap Fish sometimes sends malformated params like: app_id=guidimg=1

    if params[:img] == '1'
      redirect_to Offer.get_icon_url(:icon_id => icon_id, :source => :cloudfront) and return
    end

    @icon = Mc.get_and_put("icon.s3.#{icon_id}", false, 1.day) do
      bucket = S3.bucket(BucketNames::TAPJOY)
      image_content = bucket.get("icons/57/#{icon_id}.jpg")
      Base64.encode64 image_content
    end

  end
end
