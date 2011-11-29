class Click < SimpledbShardedResource
  self.key_format = 'udid.advertiser_app_id'
  self.num_domains = NUM_CLICK_DOMAINS

  self.sdb_attr :udid
  self.sdb_attr :publisher_app_id
  self.sdb_attr :advertiser_app_id
  self.sdb_attr :displayer_app_id
  self.sdb_attr :publisher_user_id
  self.sdb_attr :offer_id
  self.sdb_attr :currency_id
  self.sdb_attr :reward_key
  self.sdb_attr :reward_key_2
  self.sdb_attr :viewed_at,         :type => :time
  self.sdb_attr :clicked_at,        :type => :time
  self.sdb_attr :installed_at,      :type => :time
  self.sdb_attr :advertiser_amount, :type => :int
  self.sdb_attr :publisher_amount,  :type => :int
  self.sdb_attr :displayer_amount,  :type => :int
  self.sdb_attr :tapjoy_amount,     :type => :int
  self.sdb_attr :currency_reward,   :type => :int
  self.sdb_attr :spend_share,       :type => :float
  self.sdb_attr :source
  self.sdb_attr :ip_address
  self.sdb_attr :country
  self.sdb_attr :type
  self.sdb_attr :exp
  self.sdb_attr :block_reason
  self.sdb_attr :manually_resolved_at, :type => :time
  self.sdb_attr :device_name,          :cgi_escape => :true
  self.sdb_attr :publisher_partner_id
  self.sdb_attr :advertiser_partner_id
  self.sdb_attr :publisher_reseller_id
  self.sdb_attr :advertiser_reseller_id

  def initialize(options = {})
    super({ :load_from_memcache => false }.merge(options))
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_CLICK_DOMAINS

    return "clicks_#{domain_number}"
  end

  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end

  def self.select_all(options = {}, &block)
    clicks = []
    NUM_CLICK_DOMAINS.times do |i|
      Click.select(:domain_name => "clicks_#{i}", :where => options[:conditions]) do |click|
        block_given? ? yield(click) : clicks << click
      end
    end
    clicks
  end

  def rewardable?
    !(new_record? || installed_at? || clicked_at < (Time.zone.now - 2.days))
  end
end
