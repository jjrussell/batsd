##
# Represents a single web request.
class WebRequest < SimpledbResource
  
  self.sdb_attr :udid
  self.sdb_attr :app_id
  self.sdb_attr :offer_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :publisher_app_id
  self.sdb_attr :displayer_app_id
  self.sdb_attr :currency_id
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
  self.sdb_attr :device_ip
  self.sdb_attr :user_agent, :cgi_escape => true
  self.sdb_attr :time, :type => :time
  self.sdb_attr :viewed_at, :type => :time
  self.sdb_attr :path, :force_array => true, :replace => false
  self.sdb_attr :source
  self.sdb_attr :exp
  self.sdb_attr :country
  self.sdb_attr :geoip_country
  self.sdb_attr :click_key
  self.sdb_attr :transaction_id
  
  PATH_TO_STAT_MAP = {
    'connect'                        => 'logins',
    'new_user'                       => 'new_users',
    'adshown'                        => 'hourly_impressions',
    'offer_click'                    => 'paid_clicks',
    'featured_offer_click'           => 'paid_clicks',
    'conversion'                     => 'paid_installs',
    'conversion_jailbroken'          => 'jailbroken_installs',
    'featured_conversion'            => 'paid_installs',
    'featured_conversion_jailbroken' => 'jailbroken_installs',
    'daily_user'                     => 'daily_active_users',
    'monthly_user'                   => 'monthly_active_users',
    'purchased_vg'                   => 'vg_purchases',
    'get_vg_items'                   => 'vg_store_views',
    'offers'                         => 'offerwall_views',
    'featured_offer_requested'       => 'featured_offers_requested',
    'featured_offer_shown'           => 'featured_offers_shown',
  }
  
  # Params that should use the offer_id, rather than the app_id for stat tracking.
  USE_OFFER_ID = Set.new([ 'offer_click', 'featured_offer_click', 'conversion', 'conversion_jailbroken', 'featured_conversion', 'featured_conversion_jailbroken' ])
  
  PUBLISHER_PATH_TO_STAT_MAP = {
    'offer_click'                    => 'offers_opened',
    'featured_offer_click'           => 'featured_offers_opened',
    'conversion'                     => 'published_installs',
    'conversion_jailbroken'          => 'published_installs',
    'featured_conversion'            => 'featured_published_offers',
    'featured_conversion_jailbroken' => 'featured_published_offers',
  }
  
  DISPLAYER_PATH_TO_STAT_MAP = {
    'display_ad_requested'   => 'display_ads_requested',
    'display_ad_shown'       => 'display_ads_shown',
    'offer_click'            => 'display_clicks',
    'conversion'             => 'display_conversions',
    'conversion_jailbroken'  => 'display_conversions'
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
  def put_values(path, params, ip_address, geoip_data, user_agent)
    add_path(path)
    
    if params
      self.campaign_id       = params[:campaign_id]
      self.app_id            = params[:app_id]
      self.udid              = params[:udid]
      self.currency_id       = params[:currency_id]
    
      self.app_version       = params[:app_version]
      self.device_os_version = params[:device_os_version]
      self.device_type       = params[:device_type]
      self.library_version   = params[:library_version]

      self.offer_id          = params[:offer_id]
      self.publisher_app_id  = params[:publisher_app_id]
      self.advertiser_app_id = params[:advertiser_app_id]
      self.displayer_app_id  = params[:displayer_app_id]

      self.device_ip         = params[:device_ip]
      self.user_agent        = user_agent
      self.type              = params[:type]
      self.publisher_user_id = params[:publisher_user_id]
      self.virtual_good_id   = params[:virtual_good_id]

      self.source            = params[:source]
      self.exp               = params[:exp]
      self.country           = params[:country_code]
      self.transaction_id    = params[:transaction_id]
    end
    
    unless self.ip_address?
      self.ip_address = ip_address
    end
    
    self.country = geoip_data[:country] if self.country.blank?
    self.geoip_country = geoip_data[:country]
  end
  
  ##
  # Calls super.serial_save, with write_to_memcache option set to false.
  # Also increments all stats associated with this webrequest.
  def serial_save(options = {})
    self.time = @now unless self.time?
    super({:write_to_memcache => false}.merge(options))
    
    get('path', {:force_array => true}).each do |path|
      stat_name = PATH_TO_STAT_MAP[path]
      
      if stat_name.present?
        app_id = self.app_id
        if USE_OFFER_ID.include?(path)
          app_id = self.offer_id
        end
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, app_id, self.time), false, 1.day)
      end
      
      stat_name = PUBLISHER_PATH_TO_STAT_MAP[path]
      if stat_name.present?
        app_id = self.publisher_app_id
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, app_id, self.time), false, 1.day)
      end
      
      stat_name = DISPLAYER_PATH_TO_STAT_MAP[path]
      app_id = self.displayer_app_id
      if stat_name.present? && app_id.present?
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, app_id, self.time), false, 1.day)
      end
      
      if path == 'purchased_vg'
        stat_name = ['virtual_goods', self.virtual_good_id]
        Mc.increment_count(Stats.get_memcache_count_key(stat_name, self.app_id, self.time), false, 1.day)
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
    retries =     options.delete(:retries) { 5 }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    sleep_time = 0.1
    begin
      hydra = Typhoeus::Hydra.new(:max_concurrency => 20)
      count = 0
    
      MAX_WEB_REQUEST_DOMAINS.times do |i|
        SimpledbResource.count_async(:domain_name => "web-request-#{date_string}-#{i}", :where => where, :hydra => hydra) do |c|
          count += c
        end
      end
    
      hydra.run
    rescue RightAws::AwsError => e
      if retries > 0
        retries -= 1
        sleep_time *= 2
        sleep(sleep_time)
        retry
      else
        raise e
      end
    end
    
    return count
  end
end
