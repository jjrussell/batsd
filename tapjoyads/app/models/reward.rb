class Reward < SimpledbResource
  # TO REMOVE
  self.domain_name = 'reward'
  
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :offer_id
  self.sdb_attr :advertiser_amount, :type => :int
  self.sdb_attr :publisher_amount,  :type => :int
  self.sdb_attr :tapjoy_amount,     :type => :int
  self.sdb_attr :offerpal_amount,   :type => :int
  self.sdb_attr :currency_reward,   :type => :int
  self.sdb_attr :source
  self.sdb_attr :type
  self.sdb_attr :udid
  self.sdb_attr :country
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
        Stats.get_memcache_count_key('installs_revenue', get('publisher_app_id'), Time.at(get('created').to_f)), 
        false, 1.week, get('publisher_amount').to_i)
        
      Mc.increment_count(
        Stats.get_memcache_count_key('installs_spend', get('offer_id'), Time.at(get('created').to_f)), 
        false, 1.week, get('advertiser_amount').to_i)
    elsif type == 'offer' || type == 'generic'
      Mc.increment_count(
        Stats.get_memcache_count_key('offers_revenue', get('publisher_app_id'), Time.at(get('created').to_f)), 
        false, 1.week, get('publisher_amount').to_i)
      
      Mc.increment_count(
        Stats.get_memcache_count_key('installs_spend', get('offer_id'), Time.at(get('created').to_f)), 
        false, 1.week, get('advertiser_amount').to_i)
    end
  end
  
  # def dynamic_domain_name
  #   domain_number = @key.hash % NUM_REWARD_DOMAINS
  #   
  #   return "rewards_#{domain_number}"
  # end
  
  # TO REMOVE
  def serial_save(options = {})
    super(options)
    
    # save to both locations
    domain_number = @key.hash % NUM_REWARD_DOMAINS
    self.this_domain_name = "#{RUN_MODE_PREFIX}rewards_#{domain_number}"
    super(options)
    self.this_domain_name = "#{RUN_MODE_PREFIX}reward"
  end
  
end
