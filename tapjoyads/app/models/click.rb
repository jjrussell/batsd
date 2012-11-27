class Click < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "clicks"


  MAX_HISTORY = 20

  belongs_to :device, :foreign_key => 'tapjoy_device_id'
  belongs_to :publisher_app, :class_name => 'App'
  belongs_to :displayer_app, :class_name => 'App'
  belongs_to :offer
  belongs_to :currency
  belongs_to :reward, :foreign_key => 'reward_key'
  belongs_to :publisher_partner, :class_name => 'Partner'
  belongs_to :advertiser_partner, :class_name => 'Partner'
  belongs_to :publisher_reseller, :class_name => 'Reseller'
  belongs_to :advertiser_reseller, :class_name => 'Reseller'

  self.key_format = 'tapjoy_device_id.advertiser_app_id'
  self.num_domains = NUM_CLICK_DOMAINS

  self.sdb_attr :udid
  self.sdb_attr :tapjoy_device_id
  self.sdb_attr :advertising_id
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
  self.sdb_attr :client_timestamp,  :type => :time
  self.sdb_attr :mac_address
  self.sdb_attr :last_clicked_at, :type => :time, :force_array => true, :replace => false
  self.sdb_attr :last_installed_at, :type => :time, :force_array => true, :replace => false
  self.sdb_attr :offerwall_rank
  self.sdb_attr :device_type
  self.sdb_attr :geoip_country
  self.sdb_attr :force_convert, :type => :bool
  self.sdb_attr :force_converted_by
  self.sdb_attr :store_name
  self.sdb_attr :cached_offer_list_id
  self.sdb_attr :cached_offer_list_type
  self.sdb_attr :previous_publisher_ids, :type => :json, :default_value => []
  self.sdb_attr :auditioning, :type => :bool
  self.sdb_attr :instruction_viewed_at,         :type => :time
  self.sdb_attr :instruction_clicked_at,        :type => :time

  #Special case for new domain
  def self.all_domain_names
    (0...num_domains).collect { |num| "clicksV3_#{num}" }
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_CLICK_DOMAINS

    "clicksV3_#{domain_number}"
  end

  def tapjoy_device_id
    get('tapjoy_device_id') || udid
  end

  def tapjoy_device_id=(tj_id)
    put('tapjoy_device_id', tj_id)
  end

  def self.hashed_key(key)
    Digest::MD5.hexdigest(key.to_s + CLICK_KEY_SALT)
  end

  def hashed_key
    Click.hashed_key(key)
  end

  def rewardable?
    !(new_record? || installed_at? || clicked_at < (Time.zone.now - 2.days))
  end

  def successfully_rewarded?
    installed_at? && reward && reward.successful?
  end

  def publisher_user_tapjoy_device_ids
    PublisherUser.for_click(self).tapjoy_device_ids
  end

  def tapjoy_games_invitation_primary_click?
    advertiser_app_id == TAPJOY_GAMES_INVITATION_OFFER_ID &&
      key !~ /invite\[\d+\]$/
  end

  def resolve!
    raise 'Unknown click id.' if new_record?

    # We only resolve clicks in the last 48 hours.
    now = Time.zone.now
    self.manually_resolved_at = now
    if clicked_at < now - 47.hours
      self.clicked_at = now - 1.minute
    end
    save!

    d = Device.new(:key => tapjoy_device_id)
    d.unset_last_run_time!(advertiser_app_id)

    Downloader.get_with_retry(url_to_resolve) if Rails.env.production?
  end

  def resolved_too_fast?(threshold = 20.seconds)
    successfully_rewarded? &&
      type != 'video' &&
      !offer.pay_per_click? &&
      (installed_at - clicked_at) < threshold
  end

  def advertiser_app
    begin
      App.find_in_cache(advertiser_app_id, :do_lookup => true)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  def maintain_history
    if clicked_at?
      while last_clicked_at.size >= MAX_HISTORY
        delete('last_clicked_at', get('last_clicked_at', :force_array => true).min)
      end
      self.last_clicked_at = clicked_at
    end
    if installed_at?
      while last_installed_at.size >= MAX_HISTORY
        delete('last_installed_at', get('last_installed_at', :force_array => true).min)
      end
      self.last_installed_at = installed_at
    end
  end

  # For use within TJM (since dashboard URL helpers aren't available within TJM)
  def dashboard_device_info_tool_url
    uri = URI.parse(DASHBOARD_URL)
    "#{uri.scheme}://#{uri.host}/tools/device_info?click_key=#{self.key}"
  end

  def update_partner_live_dates!
    [
      [publisher_partner,  publisher_amount],
      [advertiser_partner, advertiser_amount]
    ].each do |partner, amount|
      if partner.present? && amount > 0 && partner.live_date.blank?
        partner.update_attributes!(:live_date => clicked_at)
      end
    end
  end

  def currency_reward_zero?
    currency_reward == 0
  end

  def save(options = {})
    if self.publisher_app_id_changed? && self.publisher_app_id_was.present?
      prev_publisher_data = { 'publisher_app_id' => self.publisher_app_id_was,
                              'updated_at' => self.updated_at.to_f,
                              'publisher_user_id' => self.publisher_user_id_was,
                              'currency_id' => self.currency_id_was,
                              'currency_reward' => self.currency_reward_was,
                            }
      self.previous_publisher_ids = (self.previous_publisher_ids << prev_publisher_data)
    end
    super(options)
  end

  private

  def url_to_resolve
    if type == 'generic' || type == 'survey'
      "#{API_URL}/offer_completed?click_key=#{key}"
    else
      "#{API_URL}/connect?app_id=#{advertiser_app_id}&udid=#{udid}&tapjoy_device_id=#{tapjoy_device_id}&consistent=true"
    end
  end

end
