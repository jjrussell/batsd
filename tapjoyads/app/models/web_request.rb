##
# Represents a single web request.
class WebRequest < SimpledbResource
  
  self.sdb_attr :udid
  self.sdb_attr :mac_address
  self.sdb_attr :android_id
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
  self.sdb_attr :device_name, :cgi_escape => true
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
  self.sdb_attr :language
  self.sdb_attr :screen_density
  self.sdb_attr :screen_layout_size
  self.sdb_attr :carrier_name, :cgi_escape => true   
  self.sdb_attr :allows_voip         
  self.sdb_attr :carrier_country_code
  self.sdb_attr :mobile_country_code, :cgi_escape => true
  self.sdb_attr :mobile_network_code
  self.sdb_attr :click_key
  self.sdb_attr :transaction_id
  self.sdb_attr :tap_points
  self.sdb_attr :publisher_amount, :type => :int
  self.sdb_attr :advertiser_amount, :type => :int
  self.sdb_attr :displayer_amount, :type => :int
  self.sdb_attr :tapjoy_amount, :type => :int
  self.sdb_attr :currency_reward, :type => :int
  
  PATH_TO_STAT_MAP = {
    'connect'                  => [ { :stat => 'logins',                    :attr => :app_id } ],
    'new_user'                 => [ { :stat => 'new_users',                 :attr => :app_id } ],
    'daily_user'               => [ { :stat => 'daily_active_users',        :attr => :app_id } ],
    'monthly_user'             => [ { :stat => 'monthly_active_users',      :attr => :app_id } ],
    'adshown'                  => [ { :stat => 'hourly_impressions',        :attr => :app_id } ],
    'purchased_vg'             => [ { :stat => 'vg_purchases',              :attr => :app_id } ],
    'get_vg_items'             => [ { :stat => 'vg_store_views',            :attr => :app_id } ],
    'offers'                   => [ { :stat => 'offerwall_views',           :attr => :app_id } ],
    'featured_offer_requested' => [ { :stat => 'featured_offers_requested', :attr => :app_id } ],
    'featured_offer_shown'     => [ { :stat => 'featured_offers_shown',     :attr => :app_id } ],
    'display_ad_requested'     => [ { :stat => 'display_ads_requested',     :attr => :displayer_app_id } ],
    'display_ad_shown'         => [ { :stat => 'display_ads_shown',         :attr => :displayer_app_id } ],
    'offer_click'              => [ { :stat => 'display_clicks',            :attr => :displayer_app_id },
                                    { :stat => 'offers_opened',             :attr => :publisher_app_id },
                                    { :stat => 'paid_clicks',               :attr => :offer_id } ],
    'featured_offer_click'     => [ { :stat => 'featured_offers_opened',    :attr => :publisher_app_id },
                                    { :stat => 'paid_clicks',               :attr => :offer_id } ],
  }
  STAT_TO_PATH_MAP = {
    'logins'                    => { :paths => [ 'connect' ],                             :attr_name => 'app_id' },
    'new_users'                 => { :paths => [ 'new_user' ],                            :attr_name => 'app_id' },
    'daily_active_users'        => { :paths => [ 'daily_user' ],                          :attr_name => 'app_id' },
    'monthly_active_users'      => { :paths => [ 'monthly_user' ],                        :attr_name => 'app_id' },
    'hourly_impressions'        => { :paths => [ 'adshown' ],                             :attr_name => 'app_id' },
    'vg_purchases'              => { :paths => [ 'purchased_vg' ],                        :attr_name => 'app_id' },
    'vg_store_views'            => { :paths => [ 'get_vg_items' ],                        :attr_name => 'app_id' },
    'offerwall_views'           => { :paths => [ 'offers' ],                              :attr_name => 'app_id' },
    'featured_offers_requested' => { :paths => [ 'featured_offer_requested' ],            :attr_name => 'app_id' },
    'featured_offers_shown'     => { :paths => [ 'featured_offer_shown' ],                :attr_name => 'app_id' },
    'display_ads_requested'     => { :paths => [ 'display_ad_requested' ],                :attr_name => 'displayer_app_id' },
    'display_ads_shown'         => { :paths => [ 'display_ad_shown' ],                    :attr_name => 'displayer_app_id' },
    'display_clicks'            => { :paths => [ 'offer_click' ],                         :attr_name => 'displayer_app_id' },
    'offers_opened'             => { :paths => [ 'offer_click' ],                         :attr_name => 'publisher_app_id' },
    'featured_offers_opened'    => { :paths => [ 'featured_offer_click' ],                :attr_name => 'publisher_app_id' },
    'paid_clicks'               => { :paths => [ 'offer_click', 'featured_offer_click' ], :attr_name => 'offer_id' },
  }
  
  @@domain_choices = nil
  @@domain_weights = nil
  
  def self.refresh_domain_choices_and_weights
    begin
      failures = Mc.distributed_get('failed_sdb_saves.web_request_failures') || {}
    rescue Exception => e
      failures = {}
      Notifier.alert_new_relic(e.class, e.message)
    end
    max_fails = failures.values.max
    @@domain_choices, @@domain_weights = failures.map { |domain, fails| [ domain, (fails - max_fails).abs ] }.transpose
  end
  
  def initialize(options = {})
    @now = options.delete(:time) { Time.zone.now }
    super({:load => false}.merge(options))
  end

  def dynamic_domain_name
    if rand(100) == 1
      WebRequest.refresh_domain_choices_and_weights
    end
    
    date = @now.to_s(:yyyy_mm_dd)
    if @@domain_choices.present? && @@domain_choices.first =~ /#{date}/
      domain_name = @@domain_choices.weighted_rand(@@domain_weights)
    end
    domain_name ||= "web-request-#{date}-#{rand(MAX_WEB_REQUEST_DOMAINS)}"
  end
  
  def add_path(path)
    put('path', path)
  end
  
  ##
  # Puts attributes that come from the params and request object.
  def put_values(path, params, ip_address, geoip_data, user_agent)
    add_path(path)
    
    if params
      self.campaign_id          = params[:campaign_id]
      self.app_id               = params[:app_id]
      self.udid                 = params[:udid]
      self.mac_address          = params[:mac_address]
      self.android_id           = params[:android_id]
      self.currency_id          = params[:currency_id]
                                
      self.app_version          = params[:app_version]
      self.device_os_version    = params[:device_os_version] || params[:os_version]
      self.device_type          = params[:device_type]
      self.device_name          = params[:device_name]
      self.library_version      = params[:library_version]
                                
      self.offer_id             = params[:offer_id]
      self.publisher_app_id     = params[:publisher_app_id]
      self.advertiser_app_id    = params[:advertiser_app_id]
      self.displayer_app_id     = params[:displayer_app_id]
                                
      self.device_ip            = params[:device_ip]
      self.user_agent           = user_agent
      self.type                 = params[:type]
      self.publisher_user_id    = params[:publisher_user_id]
      self.virtual_good_id      = params[:virtual_good_id]
                                
      self.source               = params[:source]
      self.exp                  = params[:exp]
      self.country              = params[:country_code]
      self.language             = params[:language]
      self.transaction_id       = params[:transaction_id]
                                
      self.tap_points           = params[:tap_points]
                                
      self.screen_density       = params[:screen_density]
      self.screen_layout_size   = params[:screen_layout_size]
                                
      self.carrier_name         = params[:carrier_name]
      self.allows_voip          = params[:allows_voip]
      self.carrier_country_code = params[:carrier_country_code]
      self.mobile_country_code  = params[:mobile_country_code]
      self.mobile_network_code  = params[:mobile_network_code]
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
    self.put('syslog_ng', '1')
    super({:write_to_memcache => false}.merge(options))
    
    update_realtime_stats
    
    WEB_REQUEST_LOGGER << self.serialize(:attributes_only => true)
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
  
  def self.count_with_vertica(conditions = nil)
    VerticaCluster.count('web_request', conditions)
  end
  
  def self.select_with_vertica(options = {})
    VerticaCluster.query('web_request', options)
  end
  
private
  
  def update_realtime_stats
    path.each do |p|
      stat_definitions = PATH_TO_STAT_MAP[p] || []
      
      stat_definitions.each do |stat_definition|
        attr_value = send(stat_definition[:attr])
        if attr_value.present?
          mc_key = Stats.get_memcache_count_key(stat_definition[:stat], attr_value, time)
          Mc.increment_count(mc_key, false, 1.day)
        end
      end
      
      if p == 'purchased_vg'
        mc_key = Stats.get_memcache_count_key([ 'virtual_goods', virtual_good_id ], app_id, time)
        Mc.increment_count(mc_key, false, 1.day)
      end
    end
  end
  
end
