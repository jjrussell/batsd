class Click < SimpledbShardedResource
  belongs_to :device, :foreign_key => 'udid'
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :displayer_app, :class_name => 'App'
  belongs_to :offer
  belongs_to :currency
  belongs_to :reward, :foreign_key => 'reward_key'
  belongs_to :publisher_partner, :class_name => 'Partner'
  belongs_to :advertiser_partner, :class_name => 'Partner'
  belongs_to :publisher_reseller, :class_name => 'Reseller'
  belongs_to :advertiser_reseller, :class_name => 'Reseller'

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

    "clicks_#{domain_number}"
  end

  def serial_save(options = {})
    super({ :write_to_memcache => false }.merge(options))
  end

  def rewardable?
    !(new_record? || installed_at? || clicked_at < (Time.zone.now - 2.days))
  end

  def successfully_rewarded?
    installed_at? && reward && reward.successful?
  end

  def publisher_user_udids
    PublisherUser.new(:key => "#{publisher_app_id}.#{publisher_user_id}").udids
  end

  def tapjoy_games_invitation_primary_click?
    advertiser_app_id == TAPJOY_GAMES_INVITATION_OFFER_ID &&
      key !~ /invite\[\d+\]$/
  end

  def resolve!
    raise 'Unknown click id.' if new_record?

    # We only resolve clicks in the last 48 hours.
    now = Time.zone.now
    self.clicked_at = now - 1.minute if clicked_at < now - 47.hours
    self.manually_resolved_at = now
    save!

    Downloader.get_with_retry url_to_resolve if Rails.env.production?
  end

  def resolved_too_fast?(threshold = 20.seconds)
    successfully_rewarded? &&
      type != 'video' &&
      !offer.pay_per_click? &&
      (installed_at - clicked_at) < threshold
  end

  private

  def url_to_resolve
    if type == 'generic'
      "#{API_URL}/offer_completed?click_key=#{key}"
    else
      "#{API_URL}/connect?app_id=#{advertiser_app_id}&udid=#{udid}&consistent=true"
    end
  end
end
