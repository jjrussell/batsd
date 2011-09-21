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
  self.sdb_attr :customer_support_username
  
  def initialize(options = {})
    super({:load_from_memcache => false}.merge(options))
    put('created', Time.zone.now.to_f.to_s) unless get('created')
  end
  
  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_REWARD_DOMAINS
    
    return "rewards_#{domain_number}"
  end
  
  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end
  
  def build_conversions
    conversions = []
    
    conversions << Conversion.new do |c|
      c.id                  = key
      c.reward_id           = key
      c.advertiser_offer_id = offer_id
      c.publisher_app_id    = publisher_app_id
      c.advertiser_amount   = advertiser_amount
      c.publisher_amount    = publisher_amount
      c.tapjoy_amount       = tapjoy_amount
      c.reward_type_string  = type
      c.created_at          = created
      c.country             = country
    end
    
    if displayer_app_id.present? && source == 'display_ad' # TO REMOVE: the source check when we fix our data corruption issues
      conversions << Conversion.new do |c|
        c.id                               = reward_key_2
        c.reward_id                        = key
        c.advertiser_offer_id              = offer_id
        c.publisher_app_id                 = displayer_app_id
        c.advertiser_amount                = 0
        c.publisher_amount                 = displayer_amount
        c.tapjoy_amount                    = 0
        c.reward_type_string_for_displayer = type
        c.created_at                       = created
        c.country                          = country
      end
    end
    
    conversions
  end
  
  def update_realtime_stats
    build_conversions.each do |c|
      c.update_realtime_stats
    end
  end
  
end
