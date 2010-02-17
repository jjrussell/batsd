##
# Represents a single web request.
class WebRequest < SimpledbResource
  include MemcachedHelper
  include ApplicationHelper
  
  PATH_TO_STAT_MAP = {
    'connect' => 'logins',
    'new_user' => 'new_users',
    'adshown' => 'hourly_impressions',
    'store_click' => 'paid_clicks',
    'store_install' => 'paid_installs'
  }
  
  # Params that should use the advertiser_app_id, rather than the app_id for stat tracking.
  USE_ADVERTISER_APP_ID = ['store_click', 'store_install']
  
  PUBLISHER_PATH_TO_STAT_MAP = {
    'store_click' => 'installs_opened',
    'store_install' => 'published_installs'
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

      put('device_ip', params[:device_ip])
      put('type', params[:type])
      put('publisher_user_id', params[:publisher_user_id])
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
    put('time', @now.to_f.to_s)
    super({:write_to_memcache => false})
    
    get('path', {:force_array => true}).each do |path|
      stat_name = PATH_TO_STAT_MAP[path]
      unless stat_name.nil?
        app_id = get('app_id')
        if USE_ADVERTISER_APP_ID.include?(path)
          app_id = get('advertiser_app_id')
        end
        increment_count_in_cache(Stats.get_memcache_count_key(stat_name, app_id, @now))
      end
      
      stat_name = PUBLISHER_PATH_TO_STAT_MAP[path]
      unless stat_name.nil?
        app_id = get('publisher_app_id')
        increment_count_in_cache(Stats.get_memcache_count_key(stat_name, app_id, @now))
      end
    end
  end
  
  ##
  # Calls super.put with the replace option false by default.
  def put(attr_name, value, options = {})
    super(attr_name, value, {:replace => false}.merge(options))
  end
end