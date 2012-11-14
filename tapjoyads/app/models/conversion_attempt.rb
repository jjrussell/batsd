class ConversionAttempt < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "conversion_attempts"

  self.num_domains = NUM_CONVERSION_ATTEMPT_DOMAINS

  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :displayer_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :advertiser_offer_id
  self.sdb_attr :currency_id
  self.sdb_attr :advertiser_amount,          :type => :int
  self.sdb_attr :publisher_amount,           :type => :int
  self.sdb_attr :displayer_amount,           :type => :int
  self.sdb_attr :tapjoy_amount,              :type => :int
  self.sdb_attr :currency_reward,            :type => :int
  self.sdb_attr :spend_share,                :type => :float
  self.sdb_attr :source
  self.sdb_attr :ip_address
  self.sdb_attr :reward_type
  self.sdb_attr :udid
  self.sdb_attr :country
  self.sdb_attr :viewed_at,                  :type => :time
  self.sdb_attr :clicked_at,                 :type => :time
  self.sdb_attr :created,                    :type => :time
  self.sdb_attr :resolution
  self.sdb_attr :block_reason
  self.sdb_attr :publisher_partner_id
  self.sdb_attr :advertiser_partner_id
  self.sdb_attr :publisher_reseller_id
  self.sdb_attr :advertiser_reseller_id
  self.sdb_attr :click_key
  self.sdb_attr :mac_address
  self.sdb_attr :device_type
  self.sdb_attr :geoip_country
  self.sdb_attr :risk_profiles,              :type => :json,  :default_value => {}
  self.sdb_attr :rules_matched,              :type => :json,  :default_value => {}
  self.sdb_attr :system_entities_offset,     :type => :float
  self.sdb_attr :individual_entities_offset, :type => :float
  self.sdb_attr :rules_offset,               :type => :float
  self.sdb_attr :processed_actions,          :type => :json,  :default_value => []
  self.sdb_attr :final_risk_score,           :type => :float
  self.sdb_attr :force_converted_by
  self.sdb_attr :store_name
  self.sdb_attr :instruction_viewed_at,      :type => :time
  self.sdb_attr :instruction_clicked_at,     :type => :time

  def after_initialize
    put('created', Time.zone.now.to_f.to_s) unless get('created')
  end

  def clear_history
    delete(:resolution)
    delete(:block_reason)
    delete(:system_entities_offset)
    delete(:individual_entities_offset)
    delete(:rules_offset)
    delete(:processed_actions)
    delete(:final_risk_score)
    self.risk_profiles = {}
    self.rules_matched = {}
    save
  end

  def add_risk_profile(profile)
    parsed_risk_profiles = risk_profiles
    parsed_risk_profiles[profile.key] = { :offset => profile.total_score_offset, :weight => profile.weight }
    self.risk_profiles = parsed_risk_profiles
  end

  def add_rule_matched(rule)
    parsed_rules_matched = rules_matched
    parsed_rules_matched[rule.name] = {
      :offset => rule.score_offset,
      :actions => rule.recommended_actions,
      :message => rule.message
    }
    self.rules_matched = parsed_rules_matched
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_CONVERSION_ATTEMPT_DOMAINS

    "conversion_attempts_#{domain_number}"
  end

end
