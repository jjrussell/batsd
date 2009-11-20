class GetAppImageController < ApplicationController
  
  def icon
    
    if ( (not params[:app_id])  )
      error = ::Error.new
      error.put('request', request.url)
      error.put('function', 'connect')
      error.put('ip', request.remote_ip)
      error.save
      Rails.logger.info "missing required params"
      render :text => "missing required params"
      return
    end
    
    @return_obj = TapjoyReturnObject.new
    
    app_id = params[:app_id].downcase
    
    image_name = "#{app_id}"
    
    image = MemcachedModel.instance.get_from_cache_and_save("icon.s3.#{image_name.hash}") do
      image_content = AWS::S3::S3Object.value image_name, 'app-icons'
      Base64.encode64 image_content
    end
    
    @return_obj.Icon = image
    
    respond_to do |f|
      f.xml {render(:partial => 'app_icon')}
    end
    
  end
end
