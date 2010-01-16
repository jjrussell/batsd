##
# Represents a single web request.
class WebRequest < SimpledbResource
  include MemcachedHelper
  include ApplicationHelper
  
  PATH_TO_STAT_MAP = {
    'connect' => 'logins',
    'new_user' => 'new_users',
    'adshown' => 'hourly_impressions'
  }
  
  def initialize(options = {})
    super({:load => false}.merge(options))
  end

  def dynamic_domain_name
    @now = Time.now.utc
    date = @now.iso8601[0,10]
    num = rand(MAX_WEB_REQUEST_DOMAINS)
    "web-request-#{date}-#{num}"
  end
  
  def add_path(path)
    put('path', path)
  end
  
  ##
  # Puts attributes that come from the params and request object.
  def put_values(path, params, request)
    add_path(path)
    put('time', @now.to_f.to_s)
    
    if params
      put('campaign_id', params[:campaign_id])
      put('app_id', params[:app_id])
      put('udid', params[:udid])
    
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
        put('ip_address', get_ip_address(request))
      end
    end
  end
  
  ##
  # Calls super.save, with write_to_memcache option set to false.
  # Also increments all stats associated with this webrequest.
  def save
    super({:write_to_memcache => false})
    
    get('path', {:force_array => true}).each do |path|
      stat_name = PATH_TO_STAT_MAP[path]
      unless stat_name.nil?
        increment_count_in_cache(Stats.get_memcache_count_key(stat_name, get('app_id'), @now))
      end
    end
  end
  
  ##
  # Calls super.put with the replace option false by default.
  def put(attr_name, value, options = {})
    super(attr_name, value, {:replace => false}.merge(options))
  end
end