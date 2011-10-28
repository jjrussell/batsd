class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  TAPJOY_MANAGED_CALLBACK_URL = 'TAP_POINTS_CURRENCY'
  NO_CALLBACK_URL = 'NO_CALLBACK'
  PLAYDOM_CALLBACK_URL = 'PLAYDOM_DEFINED'
  SPECIAL_CALLBACK_URLS = [ TAPJOY_MANAGED_CALLBACK_URL, NO_CALLBACK_URL, PLAYDOM_CALLBACK_URL ]

  belongs_to :app
  belongs_to :partner
  belongs_to :currency_group
  belongs_to :reseller

  validates_presence_of :reseller, :if => Proc.new { |currency| currency.reseller_id? }
  validates_presence_of :app, :partner, :name, :currency_group, :callback_url
  validates_numericality_of :conversion_rate, :initial_balance, :ordinal, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :spend_share, :direct_pay_share, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :rev_share_override, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1, :allow_nil => true
  validates_numericality_of :max_age_rating, :minimum_featured_bid, :minimum_offerwall_bid, :minimum_display_bid, :allow_nil => true, :only_integer => true
  validates_inclusion_of :has_virtual_goods, :only_free_offers, :send_offer_data, :hide_rewarded_app_installs, :tapjoy_enabled, :in => [ true, false ]
  validates_each :callback_url, :if => :callback_url_changed? do |record, attribute, value|
    unless SPECIAL_CALLBACK_URLS.include?(value)
      if value !~ /^https?:\/\//
        record.errors.add(attribute, 'is not a valid url')
      else
        begin
          uri = URI.parse(value)
          Resolv.getaddress(uri.host || '')
        rescue URI::InvalidURIError, Resolv::ResolvError => e
          record.errors.add(attribute, 'is not a valid url')
        end
      end
    end
  end
  validates_each :disabled_offers, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, "must be blank when using whitelisting") if record.use_whitelist? && value.present?
  end

  named_scope :for_ios, :joins => :app, :conditions => "#{App.quoted_table_name}.platform = 'iphone'"
  named_scope :just_app_ids, :select => :app_id, :group => :app_id
  named_scope :tapjoy_enabled, :conditions => 'tapjoy_enabled'
  named_scope :udid_for_user_id, :conditions => "udid_for_user_id"
  named_scope :external_publishers, :conditions => "external_publisher"

  before_validation :sanitize_attributes
  before_validation_on_create :assign_default_currency_group
  before_create :set_hide_rewarded_app_installs, :set_values_from_partner_and_reseller
  before_update :update_spend_share
  after_cache :cache_by_app_id
  after_cache_clear :clear_cache_by_app_id

  delegate :postcache_weights, :to => :currency_group
  delegate :categories, :to => :app
  memoize :postcache_weights, :categories

  def self.find_all_in_cache_by_app_id(app_id, do_lookup = (Rails.env != 'production'))
    currencies = Mc.distributed_get("mysql.app_currencies.#{app_id}.#{SCHEMA_VERSION}")
    if currencies.nil?
      if do_lookup
        currencies = find_all_by_app_id(app_id, :order => 'ordinal ASC').each { |c| c.run_callbacks(:before_cache) }
        Mc.distributed_put("mysql.app_currencies.#{app_id}.#{SCHEMA_VERSION}", currencies, false, 1.day)
      else
        currencies = []
      end
    end
    currencies
  end

  def get_visual_reward_amount(offer, display_multiplier = 1)
    display_multiplier = (display_multiplier.present? ? display_multiplier : 1).to_f
    if offer.has_variable_payment?
      orig_payment  = offer.payment
      offer.payment = offer.payment_range_low
      low           = get_reward_amount(offer) * display_multiplier
      offer.payment = offer.payment_range_high
      high          = get_reward_amount(offer) * display_multiplier
      offer.payment = orig_payment

      visual_amount = "#{low} - #{high}"
    else
      visual_amount = (get_reward_amount(offer) * display_multiplier).to_i.to_s
    end
    visual_amount
  end

  def get_reward_amount(offer)
    return 0 if conversion_rate == 0 || !offer.rewarded?

    if offer.reward_value.present?
      reward_value = offer.reward_value
    elsif offer.partner_id == partner_id
      reward_value = offer.payment
    else
      reward_value = get_publisher_amount(offer)
    end
    [reward_value * conversion_rate / 100.0, 1.0].max.to_i
  end

  def get_publisher_amount(offer, displayer_app = nil)
    if offer.partner_id == partner_id
      publisher_amount = 0
    elsif offer.direct_pay?
      publisher_amount = offer.payment * direct_pay_share
    elsif reseller_id? && reseller_id == offer.reseller_id
      publisher_amount = offer.payment * reseller_spend_share
    else
      publisher_amount = offer.payment * spend_share
    end

    if displayer_app.present?
      publisher_amount = 0
    end

    publisher_amount.to_i
  end

  def get_advertiser_amount(offer)
    if offer.partner_id == partner_id
      advertiser_amount = 0
    else
      advertiser_amount = -offer.payment
    end
    advertiser_amount
  end

  def get_tapjoy_amount(offer, displayer_app = nil)
    -get_advertiser_amount(offer) - get_publisher_amount(offer, displayer_app) - get_displayer_amount(offer, displayer_app)
  end

  def get_displayer_amount(offer, displayer_app = nil)
    displayer_app.present? ? get_publisher_amount(offer) : 0
  end

  def get_disabled_offer_ids
    Set.new(disabled_offers.split(';'))
  end
  memoize :get_disabled_offer_ids

  def get_disabled_partner_ids
    Set.new(disabled_partners.split(';'))
  end
  memoize :get_disabled_partner_ids

  def get_offer_whitelist
    Set.new(offer_whitelist.split(';'))
  end
  memoize :get_offer_whitelist

  def get_disabled_partners
    Partner.find_all_by_id(disabled_partners.split(';'))
  end

  def get_test_device_ids
    Set.new(test_devices.split(';'))
  end
  memoize :get_test_device_ids

  def tapjoy_managed?
    callback_url == TAPJOY_MANAGED_CALLBACK_URL
  end

  def set_values_from_partner_and_reseller
    self.disabled_partners = partner.disabled_partners
    self.reseller          = partner.reseller
    calculate_spend_shares
    self.direct_pay_share  = partner.direct_pay_share
    unless whitelist_overridden?
      self.offer_whitelist   = partner.offer_whitelist
      self.use_whitelist     = partner.use_whitelist
    end
    if new_record?
      self.tapjoy_enabled     = partner.approved_publisher
      self.external_publisher = partner.accepted_publisher_tos?
    end

    true
  end

  def hide_rewarded_app_installs_for_version?(app_version, source)
    return false if source == 'tj_games'
    hide_rewarded_app_installs? && (minimum_hide_rewarded_app_installs_version.blank? || app_version.present? && app_version.version_greater_than_or_equal_to?(minimum_hide_rewarded_app_installs_version))
  end

  def calculate_spend_shares
    spend_share_ratio = get_spend_share_ratio
    self.spend_share = (rev_share_override || partner.rev_share) * spend_share_ratio
    self.reseller_spend_share = reseller_id? ? reseller.reseller_rev_share * spend_share_ratio : nil
  end

  private

  def cache_by_app_id
    currencies = Currency.find_all_by_app_id(app_id, :order => 'ordinal ASC').each { |c| c.run_callbacks(:before_cache) }
    Mc.distributed_put("mysql.app_currencies.#{app_id}.#{SCHEMA_VERSION}", currencies, false, 1.day)

    if app_id_changed?
      currencies = Currency.find_all_by_app_id(app_id_was, :order => 'ordinal ASC').each { |c| c.run_callbacks(:before_cache) }
      Mc.distributed_put("mysql.app_currencies.#{app_id_was}.#{SCHEMA_VERSION}", currencies, false, 1.day)
    end
  end

  def clear_cache_by_app_id
    currencies = Currency.find_all_by_app_id(app_id, :order => 'ordinal ASC').each { |c| c.run_callbacks(:before_cache) }
    Mc.distributed_put("mysql.app_currencies.#{app_id}.#{SCHEMA_VERSION}", currencies, false, 1.day)
  end

  def get_spend_share_ratio
    Mc.distributed_get_and_put('currency.spend_share_ratio') do
      orders = Order.created_since(1.month.ago.to_date)

      sum_all_orders = orders.collect(&:amount).sum
      sum_website_orders = orders.select{|o| o.payment_method == 0}.collect(&:amount).sum
      sum_marketing_orders = orders.select{|o| o.payment_method == 2}.collect(&:amount).sum

      sum_all_orders == 0 ? 1 : (sum_all_orders - sum_marketing_orders - 0.025 * sum_website_orders) / sum_all_orders
    end
  end

  def sanitize_attributes
    self.test_devices    = test_devices.gsub(/\s/, '').downcase
    self.disabled_offers = disabled_offers.gsub(/\s/, '')
  end

  def assign_default_currency_group
    self.currency_group = CurrencyGroup.find_or_create_by_name('default')
  end

  def update_spend_share
    if rev_share_override_changed?
      calculate_spend_shares
    end
  end

  def set_hide_rewarded_app_installs
    self.hide_rewarded_app_installs = true if app.platform == 'iphone'
    true
  end

end
