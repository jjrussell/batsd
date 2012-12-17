class Reward < SimpledbShardedResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "rewards", :secondary_indexes => ["offer_id"], :read_from_riak => true

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
  self.sdb_attr :spend_share,       :type => :float
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
  self.sdb_attr :attempts,          :type => :json
  self.sdb_attr :send_currency_status
  self.sdb_attr :customer_support_username
  self.sdb_attr :publisher_partner_id
  self.sdb_attr :advertiser_partner_id
  self.sdb_attr :publisher_reseller_id
  self.sdb_attr :advertiser_reseller_id
  self.sdb_attr :click_key
  self.sdb_attr :mac_address
  self.sdb_attr :device_type
  self.sdb_attr :offerwall_rank
  self.sdb_attr :store_name
  self.sdb_attr :instruction_viewed_at, :type => :time
  self.sdb_attr :cached_offer_list_id
  self.sdb_attr :cached_offer_list_type
  self.sdb_attr :auditioning, :type => :bool

  belongs_to :offer

  def after_initialize
    put('created', Time.zone.now.to_f.to_s) unless get('created')
  end

  def dynamic_domain_name
    domain_number = @key.matz_silly_hash % NUM_REWARD_DOMAINS

    "rewards_#{domain_number}"
  end

  def build_conversions
    conversions = []

    conversions << Conversion.new do |c|
      c.id                     = key
      c.reward_id              = key
      c.advertiser_offer_id    = offer_id
      c.publisher_app_id       = publisher_app_id
      c.advertiser_amount      = advertiser_amount
      c.publisher_amount       = publisher_amount
      c.tapjoy_amount          = tapjoy_amount
      c.reward_type_string     = type
      c.created_at             = created
      c.country                = country
      c.publisher_partner_id   = publisher_partner_id
      c.advertiser_partner_id  = advertiser_partner_id
      c.publisher_reseller_id  = publisher_reseller_id
      c.advertiser_reseller_id = advertiser_reseller_id
      c.spend_share            = spend_share
      c.store_name             = store_name
    end

    if displayer_app_id.present? && source == 'display_ad'
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
        c.publisher_partner_id             = publisher_partner_id
        c.advertiser_partner_id            = advertiser_partner_id
        c.publisher_reseller_id            = publisher_reseller_id
        c.advertiser_reseller_id           = advertiser_reseller_id
        c.spend_share                      = spend_share
        c.store_name                       = store_name
      end
    end

    conversions
  end

  def update_realtime_stats
    build_conversions.each do |c|
      c.update_realtime_stats
    end
  end

  def successful?
    send_currency_status == 'OK' || send_currency_status == '200'
  end

  def fix_conditional_check_failed
    if sent_currency.present? && send_currency_status.present?
      'Already awarded'
    elsif sent_currency.nil? && send_currency_status.nil?
      'Everything is ok'
    elsif sent_currency.present? && send_currency_status.nil?
      delete('sent_currency')
      save!
      'Deleted sent_currency'
    else
      'Something weird has happened'
    end
  end

  def click
    return nil if click_key.blank?

    Click.new(:key => click_key)
  end

  def self.verify_actions_from_rewards(date)
    # find bad records
    time = Time.zone.parse(date)
    bad_actions = []
    24.times do
      v_count = VerticaCluster.count 'analytics.actions', "time >= '#{time.to_s(:db)}' and time < '#{(time + 1.hour).to_s(:db)}'"
      r_count = Reward.count(:where => "created >= '#{time.to_i}' and created < '#{(time + 1.hour).to_i}' and type != 'award_currency' and type != 'customer support' and type != 'reengagement' and type != 'test_offer' and type != 'test_video_offer'")
      Rails.logger.info "#{time} : #{r_count} - #{v_count} = #{r_count - v_count}"
      if r_count - v_count > 10
        bad_actions << time.hour
      end
      time += 1.hour
    end

    bad_actions
  end

  def self.recreate_actions_from_rewards(date)
    to_do = Reward.verify_actions_from_rewards(date)
    Rails.logger.info "running on hours: #{to_do.join(', ')}"

    rewards = {}
    count = 0
    to_do.each do |hour|
      Rails.logger.info "processing #{hour}, current count #{count}"
      start_time = hour
      end_time = start_time + 1

      VerticaCluster.query('analytics.actions', :select => 'udid, time, offer_id', :conditions => "time >= '#{date} #{start_time}:00:00' and time < '#{date} #{end_time}:00:00'").each do |r|
        rewards[r[:udid]] ||= {}
        rewards[r[:udid]][r[:offer_id]] ||= Set.new
        rewards[r[:udid]][r[:offer_id]] << r[:time].to_s(:db)
      end

      conditions = [
        "created >= '#{Time.zone.parse("#{date}  #{start_time}:00:00").to_i}'",
        "created < '#{Time.zone.parse("#{date} #{end_time}:00:00").to_i}'",
        "type != 'award_currency'",
        "type != 'customer support'",
        "type != 'reengagement'",
        "type != 'test_offer'",
        "type != 'test_video_offer'",
      ].join(' and ')

      Reward.select_all(:conditions => conditions) do |reward|
        unless rewards[reward.udid].present? && rewards[reward.udid][reward.offer_id].present? && rewards[reward.udid][reward.offer_id].include?(reward.created.to_s(:db))
          count += 1
          web_request = WebRequest.new(:time => reward.created)
          web_request.path              = 'reward'
          web_request.type              = reward.type
          web_request.publisher_app_id  = reward.publisher_app_id
          web_request.advertiser_app_id = reward.advertiser_app_id
          web_request.displayer_app_id  = reward.displayer_app_id
          web_request.offer_id          = reward.offer_id
          web_request.currency_id       = reward.currency_id
          web_request.publisher_user_id = reward.publisher_user_id
          web_request.advertiser_amount = reward.advertiser_amount
          web_request.publisher_amount  = reward.publisher_amount
          web_request.displayer_amount  = reward.displayer_amount
          web_request.tapjoy_amount     = reward.tapjoy_amount
          web_request.currency_reward   = reward.currency_reward
          web_request.source            = reward.source
          web_request.udid              = reward.udid
          web_request.country           = reward.country
          web_request.exp               = reward.exp
          web_request.viewed_at         = reward.viewed_at
          web_request.click_key         = reward.click_key
          web_request.save
        end
      end
    end
    Rails.logger.info "completed with #{count} fixes"
  end

end
