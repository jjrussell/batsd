class WebRequest < SyslogMessage

  PATH_TO_STAT_MAP = {
    'connect'                  => [ { :stat => 'logins',                    :attr => :app_id } ],
    'new_user'                 => [ { :stat => 'new_users',                 :attr => :app_id } ],
    'daily_user'               => [ { :stat => 'daily_active_users',        :attr => :app_id } ],
    'monthly_user'             => [ { :stat => 'monthly_active_users',      :attr => :app_id } ],
    'adshown'                  => [ { :stat => 'hourly_impressions',        :attr => :app_id } ],
    'purchased_vg'             => [ { :stat => 'vg_purchases',              :attr => :app_id } ],
    'get_vg_items'             => [ { :stat => 'vg_store_views',            :attr => :app_id } ],
    'offers'                   => [ { :stat => 'offerwall_views',           :attr => :app_id } ],
    'tjm_offers'               => [ { :stat => 'tjm_offerwall_views',       :attr => :app_id } ],
    'tjm_offer_click'          => [ { :stat => 'tjm_offers_opened',         :attr => :publisher_app_id },
                                    { :stat => 'paid_clicks',               :attr => :offer_id } ],
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
    'logins'                    => { :paths => [ 'connect' ],                             :attr_name => 'app_id',           :use_like => true  },
    'new_users'                 => { :paths => [ 'new_user' ],                            :attr_name => 'app_id',           :use_like => true  },
    'daily_active_users'        => { :paths => [ 'daily_user' ],                          :attr_name => 'app_id',           :use_like => true  },
    'monthly_active_users'      => { :paths => [ 'monthly_user' ],                        :attr_name => 'app_id',           :use_like => true  },
    'hourly_impressions'        => { :paths => [ 'adshown' ],                             :attr_name => 'app_id',           :use_like => false },
    'vg_purchases'              => { :paths => [ 'purchased_vg' ],                        :attr_name => 'app_id',           :use_like => false },
    'vg_store_views'            => { :paths => [ 'get_vg_items' ],                        :attr_name => 'app_id',           :use_like => false },
    'offerwall_views'           => { :paths => [ 'offers' ],                              :attr_name => 'app_id',           :use_like => false },
    'tjm_offerwall_views'       => { :paths => [ 'tjm_offers' ],                          :attr_name => 'app_id',           :use_like => false },
    'featured_offers_requested' => { :paths => [ 'featured_offer_requested' ],            :attr_name => 'app_id',           :use_like => true  },
    'featured_offers_shown'     => { :paths => [ 'featured_offer_shown' ],                :attr_name => 'app_id',           :use_like => true  },
    'display_ads_requested'     => { :paths => [ 'display_ad_requested' ],                :attr_name => 'displayer_app_id', :use_like => true  },
    'display_ads_shown'         => { :paths => [ 'display_ad_shown' ],                    :attr_name => 'displayer_app_id', :use_like => true  },
    'display_clicks'            => { :paths => [ 'offer_click' ],                         :attr_name => 'displayer_app_id', :use_like => false },
    'offers_opened'             => { :paths => [ 'offer_click' ],                         :attr_name => 'publisher_app_id', :use_like => false },
    'tjm_offers_opened'         => { :paths => [ 'tjm_offer_click' ],                     :attr_name => 'publisher_app_id', :use_like => false },
    'featured_offers_opened'    => { :paths => [ 'featured_offer_click' ],                :attr_name => 'publisher_app_id', :use_like => false },
    'paid_clicks'               => { :paths => [ 'offer_click', 'featured_offer_click', 'tjm_offer_click' ], :attr_name => 'offer_id', :use_like => false },
  }

  # alternatives keys to look in params for when calling put_values()
  PARAM_TO_ATTR_MAPPING = {
    :os_version     => :device_os_version,
    :language_code  => :language,
  }

  # alternatives keys to look in geoip_data for when put_values()
  GEOIP_TO_ATTR_MAPPING = {
    :primary_country  => :country,
    :country          => :geoip_country,
  }

  self.define_attr :udid
  self.define_attr :mac_address
  self.define_attr :sha2_udid
  self.define_attr :sha1_udid
  self.define_attr :sha1_mac_address
  self.define_attr :android_id
  self.define_attr :open_udid
  self.define_attr :open_udid_count
  self.define_attr :udid_via_lookup, :type => :bool
  self.define_attr :udid_is_temporary, :type => :bool
  self.define_attr :app_id
  self.define_attr :offer_id
  self.define_attr :advertiser_app_id
  self.define_attr :publisher_app_id
  self.define_attr :displayer_app_id
  self.define_attr :currency_id
  self.define_attr :campaign_id
  self.define_attr :publisher_user_id
  self.define_attr :virtual_good_id
  self.define_attr :device_type
  self.define_attr :device_name, :cgi_escape => true
  self.define_attr :library_version
  self.define_attr :device_os_version
  self.define_attr :app_version
  self.define_attr :type
  self.define_attr :status_items
  self.define_attr :device_ip
  self.define_attr :viewed_at, :type => :time
  self.define_attr :source
  self.define_attr :exp
  self.define_attr :country
  self.define_attr :country_code
  self.define_attr :sdk_type
  self.define_attr :plugin
  self.define_attr :language
  self.define_attr :screen_density
  self.define_attr :screen_layout_size
  self.define_attr :carrier_name, :cgi_escape => true
  self.define_attr :allows_voip
  self.define_attr :carrier_country_code
  self.define_attr :mobile_country_code, :cgi_escape => true
  self.define_attr :mobile_network_code
  self.define_attr :click_key
  self.define_attr :transaction_id
  self.define_attr :tap_points
  self.define_attr :publisher_amount, :type => :int
  self.define_attr :advertiser_amount, :type => :int
  self.define_attr :displayer_amount, :type => :int
  self.define_attr :tapjoy_amount, :type => :int
  self.define_attr :currency_reward, :type => :int
  self.define_attr :package_names, :force_array => true, :replace => false
  self.define_attr :truncated_package_names, :type => :bool
  self.define_attr :offerwall_rank, :type => :int
  self.define_attr :offerwall_rank_score, :type => :float
  self.define_attr :offerwall_start_index, :type => :int
  self.define_attr :offerwall_max_items, :type => :int
  self.define_attr :survey_question_id
  self.define_attr :survey_answer
  self.define_attr :conversion_attempt_key
  self.define_attr :resolution
  self.define_attr :block_reason
  self.define_attr :system_offset, :type => :float
  self.define_attr :individual_offset, :type => :float
  self.define_attr :rules_offset, :type => :float
  self.define_attr :risk_score, :type => :float
  self.define_attr :publisher_profile_offset, :type => :float
  self.define_attr :publisher_profile_weight, :type => :int
  self.define_attr :app_profile_offset, :type => :float
  self.define_attr :app_profile_weight, :type => :int
  self.define_attr :advertiser_profile_offset, :type => :float
  self.define_attr :advertiser_profile_weight, :type => :int
  self.define_attr :offer_profile_offset, :type => :float
  self.define_attr :offer_profile_weight, :type => :int
  self.define_attr :country_profile_offset, :type => :float
  self.define_attr :country_profile_weight, :type => :int
  self.define_attr :ipaddr_profile_offset, :type => :float
  self.define_attr :ipaddr_profile_weight, :type => :int
  self.define_attr :device_profile_offset, :type => :float
  self.define_attr :device_profile_weight, :type => :int
  self.define_attr :user_profile_offset, :type => :float
  self.define_attr :user_profile_weight, :type => :int
  self.define_attr :rule_name
  self.define_attr :rule_offset, :type => :int
  self.define_attr :rule_actions
  self.define_attr :rule_message
  self.define_attr :store_name
  self.define_attr :connection_type
  self.define_attr :format
  self.define_attr :impression_id
  self.define_attr :raw_url
  self.define_attr :controller
  self.define_attr :controller_action

  def self.count(conditions = nil)
    VerticaCluster.count('production.web_requests', conditions)
  end

  def self.select(options = {})
    VerticaCluster.query('production.web_requests', options)
  end

  def put_values(path, params, ip_address, geoip_data, user_agent)
    self.path                 = path
    self.ip_address           = ip_address
    self.user_agent           = user_agent

    save_attributes_from_hash(params, PARAM_TO_ATTR_MAPPING)
    save_attributes_from_hash(geoip_data, GEOIP_TO_ATTR_MAPPING)
    Rails.logger.info("$$$$$$$$$$$$ #{self.attributes.inspect}")
  end

  def save
    super
    begin
      update_realtime_stats
    rescue Exception => e
      Notifier.alert_new_relic(e.class, e.message)
    end
  end

  private

  def save_attributes_from_hash(attribs = {}, mapping = {})
    attribs.each do |key, value|
      if mapping[key].present?
        key_as_string = mapping[key].inspect()
      else
        key_as_string = key.inspect()
      end
      send("self.#{key_as_string}=", value) if self.attributes.has_key?(key_as_string)
    end
  end

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
