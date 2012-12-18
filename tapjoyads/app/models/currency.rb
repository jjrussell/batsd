class Currency < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  acts_as_approvable :on => :create

  attr_writer :use_offer_filter_selections
  attr_accessor :offer_filter_selections
  before_validation :convert_offer_filter
  validate    :validate_offer_filter

  # NOTE: we can't use attr_accessor_with_default due to: https://rails.lighthouseapp.com/projects/8994/tickets/4776
  def use_offer_filter_selections
    @use_offer_filter_selections || false
  end

  def convert_offer_filter
    if use_offer_filter_selections
      self.offer_filter = offer_filter_selections ? offer_filter_selections.join(',') : nil
    end
  end

  def validate_offer_filter
    offer_selections = offer_filter ? offer_filter.split(',') : nil
    if offer_selections && ((offer_selections & Offer::ACTIVE_OFFER_TYPES).length != offer_selections.length)
      invalid_offers = offer_selections - (offer_selections & Offer::ACTIVE_OFFER_TYPES)
      errors.add(:offer_filter, "contains invalid offer types #{invalid_offers.join(',')}")
    end
  end

  json_set_field :promoted_offers

  TAPJOY_MANAGED_CALLBACK_URL = 'TAP_POINTS_CURRENCY'
  NO_CALLBACK_URL = 'NO_CALLBACK'
  SPECIAL_CALLBACK_URLS = [ TAPJOY_MANAGED_CALLBACK_URL, NO_CALLBACK_URL ]
  DEFAULT_MULTIPLIER = 1.0

  NON_REWARDED_NAME = "Non-Rewarded"

  belongs_to :app
  belongs_to :partner
  belongs_to :currency_group
  belongs_to :reseller

  has_many :reengagement_offers
  has_many :currency_sales
  has_one :deeplink_offer, :required => true
  has_many :conversion_rates

  validates_presence_of :reseller, :if => Proc.new { |currency| currency.reseller_id? }
  validates_presence_of :app, :partner, :name, :currency_group, :callback_url
  validates_numericality_of :conversion_rate, :initial_balance, :ordinal, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :spend_share, :direct_pay_share, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :rev_share_override, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1, :allow_nil => true
  validates_numericality_of :max_age_rating, :minimum_featured_bid, :minimum_offerwall_bid, :minimum_display_bid, :allow_nil => true, :only_integer => true
  validates_inclusion_of :only_free_offers, :send_offer_data, :hide_rewarded_app_installs, :tapjoy_enabled, :message_enabled, :in => [ true, false ]
  validates_each :conversion_rate, :if => :conversion_rate_changed? do |record, attribute, value|
    if record.conversion_rates.any?
      record.conversion_rates.each do |conversion_rate|
        if record.conversion_rate >= conversion_rate.rate
          record.errors.add(attribute, 'Cannot update the conversion rate to a value greater than any of the custom conversion rates you have already set. You must clean up your custom conversion rates or use a lower conversion rate value that does not conflict.')
          break
        end
      end
    end
  end
  validates_each :callback_url, :if => :callback_url_changed? do |record, attribute, value|
    if record.conversion_rate == 0 && value != NO_CALLBACK_URL
      record.errors.add(attribute, "must be set to #{NO_CALLBACK_URL} for non-rewarded currencies")
    elsif SPECIAL_CALLBACK_URLS.include?(value)
      if record.conversion_rate > 0 && (record.app.currencies.size > 1 || record.new_record? && record.app.currencies.any?)
        record.errors.add(attribute, 'cannot be managed if the app has multiple currencies')
      end
    else
      if value !~ /^https?:\/\//
        record.errors.add(attribute, 'is not a valid url')
      else
        begin
          uri = URI.parse(value)
          Resolv.getaddress(uri.host || '')
        rescue URI::InvalidURIError => e
          record.errors.add(attribute, 'is not a valid url')
        rescue Resolv::ResolvError => e
          record.errors.add(attribute, 'host cannot be resolved')
        end
      end
    end
  end
  validates_each :disabled_offers, :allow_blank => true do |record, attribute, value|
    record.errors.add(attribute, "must be blank when using whitelisting") if record.use_whitelist? && value.present?
  end
  validates_each :test_devices do |record, attribute, value|
    if record.has_invalid_test_devices?
      record.errors.add(attribute, "includes invalid device IDs")
    end
  end
  validates_each :conversion_rate, :on => :update do |record, attribute, value|
    if value != record.conversion_rate_was
      if value == 0
        record.errors.add(:conversion_rate, "cannot be set to 0")
      elsif record.conversion_rate_was == 0
        record.errors.add(:conversion_rate, "cannot change from 0")
      end
    end
  end

  def has_invalid_test_devices?
    get_test_device_ids(:reload).any? do |device_id|
      device_id.blank? || device_id.length > 100
    end
  end

  scope :for_ios, :joins => :app, :conditions => "#{App.quoted_table_name}.platform = 'iphone'"
  scope :just_app_ids, :select => :app_id, :group => :app_id
  scope :rewarded, :conditions => 'conversion_rate > 0'
  scope :non_rewarded, :conditions => 'conversion_rate = 0'
  scope :tapjoy_enabled, :conditions => 'tapjoy_enabled'
  scope :udid_for_user_id, :conditions => "udid_for_user_id"
  scope :external_publishers, :conditions => "external_publisher and tapjoy_enabled"
  scope :ordered_by_app_name, :include => [ :app, :partner ], :order => 'apps.name, partners.name'
  scope :search_name, lambda { |term|
    { :conditions => [ "tapjoy_enabled and name like ?", term ] }
  }
  scope :search_app_name, lambda { |term|
    {
      :joins => [ :app ],
      :conditions => [ "tapjoy_enabled and apps.name like ?", term ]
    }
  }
  scope :search_partner_name, lambda { |term|
    {
      :joins => [ :partner ],
      :conditions => [ "tapjoy_enabled and partners.name like ?", term ]
    }
  }

  before_validation :sanitize_attributes
  before_validation :assign_default_currency_group, :on => :create
  before_create :set_hide_rewarded_app_installs, :set_values_from_partner_and_reseller, :set_promoted_offers
  before_create :create_deeplink_offer
  before_update :update_spend_share
  before_update :reset_to_pending_if_rejected
  after_update  :approve_on_tapjoy_enabled
  after_commit :cache_by_app_id, :on => :create
  after_commit :cache_by_app_id, :on => :update
  set_callback :cache_clear, :after, :clear_cache_by_app_id

  delegate :postcache_weights, :to => :currency_group
  delegate :categories, :to => :app
  delegate :get_promoted_offers, :enable_risk_management?, :to => :partner, :prefix => true
  memoize :postcache_weights, :categories, :partner_get_promoted_offers, :partner_enable_risk_management?

  delimited_field :test_devices

  def self.columns
    super.reject do |c|
      c == "minimum_hide_rewarded_app_installs_version"
    end
  end

  def has_test_device?(udid)
    udid = udid.id if udid.is_a?(Device)
    get_test_device_ids.include?(udid)
  end

  def self.find_all_in_cache_by_app_id(app_id, do_lookup = !Rails.env.production?)
    currencies = Mc.distributed_get("mysql.app_currencies.#{app_id}.#{acts_as_cacheable_version}")
    if currencies.nil?
      if do_lookup
        ActiveRecordDisabler.with_queries_enabled do
          currencies = find_all_by_app_id(app_id, :order => 'ordinal ASC').each { |c| c }
          Mc.distributed_put("mysql.app_currencies.#{app_id}.#{acts_as_cacheable_version}", currencies, false, 1.day)
        end
      else
        currencies = []
      end
    end
    currencies
  end

  def self.find_non_rewarded_currency_in_cache_by_app_id(app_id, do_lookup = !Rails.env.production?)
    currencies = self.find_all_in_cache_by_app_id(app_id, do_lookup)
    currencies.detect { |c| c.non_rewarded? } if currencies.present?
  end

  def has_special_callback?
    SPECIAL_CALLBACK_URLS.include?(callback_url)
  end

  def get_spend_share(offer)
    if partner_id == offer.partner_id
      0
    elsif offer.direct_pay?
      direct_pay_share
    elsif reseller_id? && reseller_id == offer.reseller_id
      reseller_spend_share
    else
      spend_share
    end
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
    return 0 unless rewarded? && offer.rewarded?
    ([get_raw_reward_value(offer), 1.0].max.to_i * currency_sale_multiplier).to_i
  end

  def get_raw_reward_value(offer)
    return 0 unless rewarded? && offer.rewarded?

    if offer.reward_value.present?
      reward_value = offer.reward_value
    elsif offer.partner_id == partner_id
      reward_value = offer.payment
    else
      reward_value = floored_reward_value(offer)
    end
    reward_value * currency_conversion_rate(offer) / 100.0
  end

  def currency_conversion_rate(offer)
    if self.conversion_rate_enabled?
      all_conversion_rates.select do |conversion_rate|
        conversion_rate.minimum_offerwall_bid <= self.get_publisher_amount(offer)
      end.last.try(:rate) || self.conversion_rate
    else
      self.conversion_rate
    end
  end

  def all_conversion_rates
    Array self.conversion_rates.all(:order => 'minimum_offerwall_bid')
  end
  memoize :all_conversion_rates

  def get_publisher_amount(offer, displayer_app = nil)
    if displayer_app.present?
      0
    elsif offer.payment == 2
      1
    else
      floored_reward_value(offer)
    end
  end

  def get_advertiser_amount(offer)
    if offer.partner_id == partner_id
      advertiser_amount = 0
    else
      advertiser_amount = -offer.payment
    end
    advertiser_amount
  end

  def currency_sale_multiplier
    active_currency_sale.try(:multiplier) || DEFAULT_MULTIPLIER
  end

  def active_currency_sale
    now = Time.zone.now
    Array(self.currency_sales.find(:first, :conditions => ["start_time <= ? AND end_time > ? AND disabled_at is null", now, now])).first
  end
  memoize :active_currency_sale

  def active_currency_sale?
    active_currency_sale.present?
  end

  def next_currency_sale
    now = Time.zone.now
    Array(self.currency_sales.find(:first, :conditions => [ "start_time > ? AND end_time > ? AND disabled_at is null", now, now ], :order => 'start_time')).first
  end
  memoize :next_currency_sale

  def next_currency_sale?
    next_currency_sale.present?
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
    find_all_in_string(Partner, disabled_partners)
  end

  def get_disabled_offers
    find_all_in_string(Offer, disabled_offers)
  end

  def get_test_device_ids
    test_devices
  end
  memoize :get_test_device_ids

  def get_store_whitelist
    Set.new(store_whitelist.split(';'))
  end
  memoize :get_store_whitelist

  def tapjoy_managed?
    callback_url == TAPJOY_MANAGED_CALLBACK_URL
  end

  def update_promoted_offers(offer_ids)
    self.promoted_offers = offer_ids.sort
    changed? ? save : true
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
    if new_record? && (id == app_id)
      self.tapjoy_enabled     = partner.approved_publisher
      self.external_publisher = partner.accepted_publisher_tos?
    end

    true
  end

  def set_promoted_offers
    self.promoted_offers = app.currencies.present? ? app.currencies.first.get_promoted_offers : ''
    true
  end

  def calculate_spend_shares
    spend_share_ratio = [ SpendShare.current_ratio, 1 - partner.max_deduction_percentage ].max
    self.spend_share = (rev_share_override || partner.rev_share) * spend_share_ratio
    self.reseller_spend_share = reseller_id? ? reseller.reseller_rev_share * spend_share_ratio : nil
  end

  def after_approve(approval)
    self.tapjoy_enabled = true
    self.save
  end

  def rewarded?
    conversion_rate > 0
  end

  def non_rewarded?
    !self.rewarded?
  end

  def approve!
    self.approval.approve!(true)
  end

  # For use within TJM (since dashboard URL helpers aren't available within TJM)
  def dashboard_app_currency_url
    uri = URI.parse(DASHBOARD_URL)
    "#{uri.scheme}://#{uri.host}/apps/#{self.app_id}/currencies/#{self.id}"
  end

  def charges?(offer)
    get_advertiser_amount(offer) != 0
  end

  private

  def cache_by_app_id
    currencies = Currency.find_all_by_app_id(app_id, :conditions => [ 'tapjoy_enabled = ?', true ], :order => 'ordinal ASC').each { |c| c.run_callbacks(:cache); c }
    memcache_distributed_put(app_id, currencies)

    if app_id_changed?
      currencies = Currency.find_all_by_app_id(app_id_was, :conditions => [ 'tapjoy_enabled = ?', true ], :order => 'ordinal ASC').each { |c| c.run_callbacks(:cache); c }
      memcache_distributed_put(app_id_was, currencies)
    end
  end

  def clear_cache_by_app_id
    currencies = Currency.find_all_by_app_id(app_id, :order => 'ordinal ASC').each { |c| c }
    memcache_distributed_put(app_id, currencies)
  end

  def memcache_distributed_put(app_id, currencies)
    Mc.distributed_put("mysql.app_currencies.#{app_id}.#{Currency.acts_as_cacheable_version}", currencies, false, 1.day)
  end

  def sanitize_attributes
    self.test_devices = test_devices.to_a.collect { |val| val.to_s.gsub(/\s/, '') }.reject { |val| val.blank? }
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

  def reset_to_pending_if_rejected
    if self.rejected?
      self.approval.destroy
      new_approval = Approval.new(:item_id => id, :item_type => self.class.name, :event => 'create', :created_at => nil, :updated_at => nil)
      new_approval.save
    end
  end

  def create_deeplink_offer
    build_deeplink_offer(:partner => partner, :app => app)
    self.enabled_deeplink_offer_id = deeplink_offer.id
    true
  end

  def approve_on_tapjoy_enabled
    if self.pending? && self.tapjoy_enabled_changed? && self.tapjoy_enabled?
      self.approve!
    end
  end

  def find_all_in_string(model, str_list)
    model.find_all_by_id(str_list.split(';'))
  end

  def floored_reward_value(offer)
    floored_value = (offer.payment * get_spend_share(offer)).to_i
    if get_advertiser_amount(offer) < 0 && floored_value == 0
      1
    else
      floored_value
    end
  end
end
