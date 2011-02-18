class Reward < SimpledbShardedResource
  self.num_domains = NUM_REWARD_DOMAINS
  
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :displayer_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :offer_id
  self.sdb_attr :currency_id
  self.sdb_attr :advertiser_amount, :type => :int
  self.sdb_attr :publisher_amount,  :type => :int
  self.sdb_attr :displayer_amount,  :type => :int
  self.sdb_attr :tapjoy_amount,     :type => :int
  self.sdb_attr :offerpal_amount,   :type => :int
  self.sdb_attr :currency_reward,   :type => :int
  self.sdb_attr :source
  self.sdb_attr :type
  self.sdb_attr :udid
  self.sdb_attr :country
  self.sdb_attr :reward_key_2
  self.sdb_attr :exp
  self.sdb_attr :viewed_at,         :type => :time
  self.sdb_attr :created,           :type => :time
  self.sdb_attr :sent_currency,     :type => :time
  self.sdb_attr :sent_money_txn,    :type => :time
  self.sdb_attr :send_currency_status
  
  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
    put('created', Time.zone.now.to_f.to_s) unless get('created')
  end
  
  def update_counters
    publisher_revenue_stat = case type
    when 'install'
      'installs_revenue'
    when 'offer', 'generic', 'action'
      'offers_revenue'
    when 'featured_install', 'featured_offer', 'featured_generic', 'featured_action'
      'featured_revenue'
    else
      nil
    end
    
    if publisher_revenue_stat.present?
      mc_key = Stats.get_memcache_count_key(publisher_revenue_stat, publisher_app_id, created)
      Mc.increment_count(mc_key, false, 1.day, publisher_amount)
    end
    
    mc_key = Stats.get_memcache_count_key('installs_spend', offer_id, created)
    Mc.increment_count(mc_key, false, 1.day, advertiser_amount)

    mc_key = Stats.get_memcache_count_key('installs_spend', offer_id, created, self.country)
    Mc.increment_count(mc_key, false, 1.day, advertiser_amount)

    if displayer_app_id.present?
      mc_key = Stats.get_memcache_count_key('display_revenue', displayer_app_id, created)
      Mc.increment_count(mc_key, false, 1.day, displayer_amount)
    end
  end
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_REWARD_DOMAINS
    
    return "rewards_#{domain_number}"
  end
  
  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end
  
end
