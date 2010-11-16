##
# Represents a single web request.
class WebRequest < SimpledbResource
  
  self.sdb_attr :udid
  self.sdb_attr :app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :publisher_app_id
  self.sdb_attr :campaign_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :virtual_good_id
  self.sdb_attr :ip_address
  self.sdb_attr :device_type
  self.sdb_attr :library_version
  self.sdb_attr :device_os_version
  self.sdb_attr :app_version
  self.sdb_attr :type
  self.sdb_attr :status_items
  self.sdb_attr :time, :type => :time
  self.sdb_attr :viewed_at, :type => :time
  self.sdb_attr :path, :force_array => true, :replace => false
  self.sdb_attr :exp
  
  PATH_TO_STAT_MAP = {
    'connect' => 'logins',
    'new_user' => 'new_users',
    'adshown' => 'hourly_impressions',
    'store_click' => 'paid_clicks',
    'offer_click' => 'paid_clicks',
    'conversion' => 'paid_installs',
    'conversion_jailbroken' => 'jailbroken_installs',
    'daily_user' => 'daily_active_users',
    'monthly_user' => 'monthly_active_users',
    'purchased_vg' => 'vg_purchases',
    'offers' => 'offerwall_views'
  }
  
  # Params that should use the offer_id, rather than the app_id for stat tracking.
  USE_OFFER_ID = [ 'store_click', 'offer_click', 'conversion', 'conversion_jailbroken' ]
  
  PUBLISHER_PATH_TO_STAT_MAP = {
    'store_click' => 'installs_opened',
    'offer_click' => 'offers_opened',
    'conversion' => 'published_installs',
    'conversion_jailbroken' => 'published_installs'
  }
  
  DISPLAYER_PATH_TO_STAT_MAP = {
    'display_ad_requested' => 'display_ads_requested',
    'display_ad_shown' => 'display_ads_shown',
    'store_click' => 'display_clicks',
    'offer_click' => 'display_clicks',
    'conversion' => 'display_conversions',
    'conversion_jailbroken' => 'display_conversions'
  }
  
  @@bad_domains = {}
  
  def initialize(options = {})
    @now = options.delete(:time) { Time.zone.now }
    super({:load => false}.merge(options))
  end

  def dynamic_domain_name
    date = @now.strftime('%Y-%m-%d')
    num = rand(MAX_WEB_REQUEST_DOMAINS)
    domain_name = "web-request-#{date}-#{num}"

    if rand(100) == 1 
      @@bad_domains = Mc.get('failed_sdb_saves.bad_domains') || {}
    end
    
    if @@bad_domains[domain_name]
      num = rand(MAX_WEB_REQUEST_DOMAINS)
      domain_name = "web-request-#{date}-#{num}"
    end
    
    domain_name
  end
  
  def add_path(path)
    put('path', path)
  end
  
  ##
  # Puts attributes that come from the params and request object.
  def put_values(path, params, ip_address, geoip_data)
    add_path(path)
    
    if params
      put('campaign_id', params[:campaign_id])
      put('app_id', params[:app_id])
      put('udid', params[:udid])
      put('currency_id', params[:currency_id])
    
      put('app_version', params[:app_version])
      put('device_os_version', params[:device_os_version])
      put('device_type', params[:device_type])
      put('library_version', params[:library_version])
      
      put('offer_id', params[:offer_id])
      put("publisher_app_id", params[:publisher_app_id])
      put("advertiser_app_id", params[:advertiser_app_id])
      put("displayer_app_id", params[:displayer_app_id])

      put('device_ip', params[:device_ip])
      put('type', params[:type])
      put('publisher_user_id', params[:publisher_user_id])
      put('virtual_good_id', params[:virtual_good_id])

      put('source', params[:source])
      put('exp', params[:exp])
    end
    
    unless get('ip_address')
      put('ip_address', ip_address)
    end
    
    put('country', geoip_data[:country])
  end
  
  ##
  # Calls super.save, with write_to_memcache option set to false.
  # Also increments all stats associated with this webrequest.
  def save
    put('time', @now.to_f.to_s) unless get('time')
    super({:write_to_memcache => false})
    
    get('path', {:force_array => true}).each do |path|
      stat_name = PATH_TO_STAT_MAP[path]
      if stat_name.present?
        app_id = get('app_id')
        if USE_OFFER_ID.include?(path)
          app_id = get('offer_id')
        end
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, app_id, self.time))
      end
      
      stat_name = PUBLISHER_PATH_TO_STAT_MAP[path]
      if stat_name.present?
        app_id = get('publisher_app_id')
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, app_id, self.time))
      end
      
      stat_name = DISPLAYER_PATH_TO_STAT_MAP[path]
      app_id = get('displayer_app_id')
      if stat_name.present? && app_id.present?
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, app_id, self.time))
      end
    end
  end
  
  ##
  # Calls super.put with the replace option false by default.
  def put(attr_name, value, options = {})
    super(attr_name, value, {:replace => false}.merge(options))
  end
  
  def self.count(options = {})
    date_string = options.delete(:date) { Time.zone.now.to_date.to_s(:db) }
    where =       options.delete(:where)
    retries =     options.delete(:retries) { 10 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    count = 0
    MAX_WEB_REQUEST_DOMAINS.times do |i|
      count += SimpledbResource.count(
          :domain_name => "web-request-#{date_string}-#{i}", 
          :where => where,
          :retries => retries)
    end
    
    count
  end
  
  def self.count_async(options = {})
    date_string = options.delete(:date) { Time.zone.now.to_date.to_s(:db) }
    where =       options.delete(:where)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    hydra = Typhoeus::Hydra.new
    count = 0
    
    MAX_WEB_REQUEST_DOMAINS.times do |i|
      SimpledbResource.count_async(:domain_name => "web-request-#{date_string}-#{i}", :where => where, :hydra => hydra) do |c|
        count += c
      end
    end
    
    hydra.run
    
    return
  end
end
