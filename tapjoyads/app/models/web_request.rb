##
# Represents a single web request.
class WebRequest < SimpledbResource
  include MemcachedHelper
  
  PATH_TO_STAT_MAP = {
    'connect' => 'login',
    'new_user' => 'new_users',
    'adshown' => 'hourly_impressions'
  }
  
  def initialize(path, params, request)
    @now = Time.now.utc
    date = @now.iso8601[0,10]
    
    key = UUIDTools::UUID.random_create.to_s
    num = rand(MAX_WEB_REQUEST_DOMAINS)
    domain_name = "web-request-#{date}-#{num}"
    
    super domain_name, key, {:load => false}
    
    put('path', path)
    put('time', @now.to_f.to_s)
    
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
      
      put('ip_address', params[:device_ip])
    end
    
    if request
      unless get('ip_address')
        ip_address = request.headers['X-Forwarded-For'] || request.remote_ip
        ip_address.gsub!(/,.*$/, '')
        put('ip_address', ip_address)
      end
    end
  end
  
  def save
    super({:write_to_memcache => false})
    
    if PATH_TO_STAT_MAP.include?(get('path'))
      stat_name = PATH_TO_STAT_MAP[get('path')]
      increment_count_in_cache(Stats.get_memcache_count_key(stat_name, get('app_id'), @now))
    end
  end
end