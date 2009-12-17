##
# Represents a single web request.
class WebRequest < SimpledbResource
  
  def initialize(path, params, headers)
    now = Time.now.utc
    date = now.iso8601[0,10]
    
    key = UUIDTools::UUID.random_create.to_s
    num = rand(MAX_WEB_REQUEST_DOMAINS)
    domain_name = "web-request-#{date}-#{num}"
    
    super domain_name, key, {:load => false}
    
    put('path', path)
    put('time', now.to_f.to_s)
    
    if params
      put('campaign_id', params[:campaign_id])
      put('app_id', params[:app_id])
      put('udid', params[:udid])
      #put('slot_id', params[:slot_id])
    
      put('app_version', params[:app_version])
      put('device_os_version', params[:device_os_version])
      put('device_type', params[:device_type])
      put('library_version', params[:library_version])
      
      put('offer_id', params[:offer_id])
      put("publisher_app_id", params[:publisher_app_id])
      put("advertiser_app_id", params[:advertiser_app_id])
    end
    
    if request
      put('ip_address', request.remote_ip)
    end
  end
  
  def save
    super({:write_to_memcache => false})
    
  end
end