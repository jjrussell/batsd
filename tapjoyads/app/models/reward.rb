class Reward < SimpledbShardedResource
  self.num_domains = NUM_REWARD_DOMAINS
  
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :displayer_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :offer_id
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
  self.sdb_attr :created,           :type => :time
  self.sdb_attr :sent_currency,     :type => :time
  self.sdb_attr :sent_money_txn,    :type => :time
  
  def initialize(options = {})
    super
    put('created', Time.zone.now.to_f.to_s) unless get('created')
  end
  
  def update_counters
    if type == 'install'
      Mc.increment_count(
        Stats.get_memcache_count_key('installs_revenue', publisher_app_id, created), 
        false, 1.week, publisher_amount)
        
      Mc.increment_count(
        Stats.get_memcache_count_key('installs_spend', offer_id, created), 
        false, 1.week, advertiser_amount)
    elsif type == 'offer' || type == 'generic'
      Mc.increment_count(
        Stats.get_memcache_count_key('offers_revenue', publisher_app_id, created), 
        false, 1.week, publisher_amount)
      
      Mc.increment_count(
        Stats.get_memcache_count_key('installs_spend', offer_id, created), 
        false, 1.week, advertiser_amount)
    end
    
    if displayer_app_id.present?
      Mc.increment_count(
        Stats.get_memcache_count_key('display_revenue', displayer_app_id, created),
        false, 1.week, displayer_amount)
    end
  end
  
  def dynamic_domain_name
    domain_number = @key.hash % NUM_REWARD_DOMAINS
    
    return "rewards_#{domain_number}"
  end
  
end
