class Offer < ActiveRecord::Base
  include ActiveModel::Validations
  include UuidPrimaryKey
  include Offer::Ranking
  include Offer::Rejecting
  include Offer::UrlGeneration
  include Offer::BannerCreatives
  include Offer::ThirdPartyTracking
  include Offer::Optimization
  include Offer::Budgeting
  acts_as_cacheable
  acts_as_tracking
  acts_as_trackable

  APPLE_DEVICES = %w( iphone itouch ipad )
  IPAD_DEVICES = %w( ipad )
  ANDROID_DEVICES = %w( android )
  WINDOWS_DEVICES = %w( windows )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES + WINDOWS_DEVICES
  ALL_OFFER_TYPES = %w( App EmailOffer GenericOffer OfferpalOffer RatingOffer ActionOffer VideoOffer SurveyOffer ReengagementOffer DeeplinkOffer Coupon)
  OBSOLETE_OFFER_TYPES = %w(EmailOffer OfferpalOffer RatingOffer)
  ACTIVE_OFFER_TYPES = ALL_OFFER_TYPES - OBSOLETE_OFFER_TYPES
  REWARDED_APP_INSTALL_OFFER_TYPES = Set.new(%w( App EmailOffer OfferpalOffer RatingOffer ReengagementOffer))
  ALL_SOURCES = %w( offerwall display_ad featured tj_games )

  CLASSIC_OFFER_TYPE                          = '0'
  DEFAULT_OFFER_TYPE                          = '1'
  FEATURED_OFFER_TYPE                         = '2'
  DISPLAY_OFFER_TYPE                          = '3'
  NON_REWARDED_DISPLAY_OFFER_TYPE             = '4'
  NON_REWARDED_FEATURED_OFFER_TYPE            = '5'
  VIDEO_OFFER_TYPE                            = '6'
  FEATURED_BACKFILLED_OFFER_TYPE              = '7'
  NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE = '8'
  REENGAGEMENT_OFFER_TYPE                     = '9'
  NON_REWARDED_BACKFILLED_OFFER_TYPE          = '10'
  OFFER_TYPE_NAMES = {
    DEFAULT_OFFER_TYPE                          => 'Offerwall Offers',
    FEATURED_OFFER_TYPE                         => 'Rewarded Featured Offers',
    DISPLAY_OFFER_TYPE                          => 'Display Ad Offers',
    NON_REWARDED_DISPLAY_OFFER_TYPE             => 'Non-Rewarded Display Ad Offers',
    NON_REWARDED_FEATURED_OFFER_TYPE            => 'Non-Rewarded Featured Offers',
    VIDEO_OFFER_TYPE                            => 'Video Offers',
    FEATURED_BACKFILLED_OFFER_TYPE              => 'Rewarded Featured Offers (Backfilled)',
    NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE => 'Non-Rewarded Featured Offers (Backfilled)',
    REENGAGEMENT_OFFER_TYPE                     => 'Reengagement Offers',
    NON_REWARDED_BACKFILLED_OFFER_TYPE          => 'Non-Rewarded Offers (Backfilled)'
  }

  FEATURED_AD_BACKGROUNDS = %w(bg-dark-purple bg-blue bg-green bg-dark bg-purple)
  DEFAULT_FEATURED_AD_BACKGROUND = FEATURED_AD_BACKGROUNDS.first

  OFFER_LIST_EXCLUDED_COLUMNS = %w( account_manager_notes
                                    active
                                    allow_negative_balance
                                    audition_factor
                                    auto_update_icon
                                    created_at
                                    daily_budget
                                    daily_cap_type
                                    hidden
                                    instructions
                                    instructions_overridden
                                    last_daily_stats_aggregation_time
                                    last_stats_aggregation_time
                                    low_balance
                                    min_bid_override
                                    min_conversion_rate
                                    name_suffix
                                    next_daily_stats_aggregation_time
                                    next_stats_aggregation_time
                                    overall_budget
                                    pay_per_click
                                    source_offer_id
                                    stats_aggregation_interval
                                    tapjoy_enabled
                                    tapjoy_sponsored
                                    tracking_for_id
                                    tracking_for_type
                                    updated_at
                                    url_overridden
                                    user_enabled )

  OFFER_LIST_REQUIRED_COLUMNS = (Offer.column_names - OFFER_LIST_EXCLUDED_COLUMNS).map { |c| "#{quoted_table_name}.#{c}" }.join(', ')

  DIRECT_PAY_PROVIDERS = %w( boku paypal )

  FREQUENCIES_CAPPING_INTERVAL = {
    'none'     => 0,
    '1 minute' => 1.minute.to_i,
    '1 hour'   => 1.hour.to_i,
    '8 hours'  => 8.hours.to_i,
    '24 hours' => 24.hours.to_i,
    '2 days'   => 2.days.to_i,
    '3 days'   => 3.days.to_i,
  }

  MC_KEY_AGE_GATING_PREFIX = 'offer.age_gating.device.offer'

  PAY_PER_CLICK_TYPES = {:non_ppc => 0, :ppc_on_offerwall => 1, :ppc_on_instruction => 2}

  attr_reader :video_button_tracking_offers
  attr_accessor :cached_offer_list_id
  attr_accessor :cached_offer_list_type
  attr_writer :auditioning

  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  has_many :rank_boosts
  has_many :enable_offer_requests
  has_many :dependent_action_offers, :class_name => 'ActionOffer', :foreign_key => :prerequisite_offer_id
  has_many :offer_events
  has_many :editors_picks
  has_many :approvals, :class_name => 'CreativeApprovalQueue'
  has_many :brands, :through => :brand_offer_mappings
  has_many :brand_offer_mappings
  has_many :sales_reps

  belongs_to :partner
  belongs_to :item, :polymorphic => true
  belongs_to :reseller
  belongs_to :app, :foreign_key => "item_id"
  belongs_to :action_offer, :foreign_key => "item_id"
  belongs_to :generic_offer, :foreign_key => "item_id"
  belongs_to :app_metadata
  belongs_to :source_offer, :class_name => 'Offer'
  belongs_to :prerequisite_offer, :class_name => 'Offer'
  belongs_to :coupon, :foreign_key => "item_id"

  validates_presence_of :reseller, :if => Proc.new { |offer| offer.reseller_id? }
  validates_presence_of :partner, :item, :name, :url, :rank_boost, :optimized_rank_boost
  validates_presence_of :prerequisite_offer, :if => Proc.new { |offer| offer.prerequisite_offer_id? }
  validates_length_of :featured_ad_content, :maximum => 256, :allow_nil => true
  validates_length_of :featured_ad_action, :maximum => 24, :allow_nil => true
  validates_inclusion_of :featured_ad_color, :in => FEATURED_AD_BACKGROUNDS, :allow_blank => true
  validates_numericality_of :price, :interval, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :bid, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :min_bid_override, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :rank_boost, :optimized_rank_boost, :allow_nil => false, :only_integer => true
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :in => PAY_PER_CLICK_TYPES.map {|label, value| value}
  validates_inclusion_of :user_enabled, :tapjoy_enabled, :allow_negative_balance, :self_promote_only, :featured, :multi_complete, :rewarded, :cookie_tracking, :requires_udid, :requires_mac_address, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => ALL_OFFER_TYPES
  validates_inclusion_of :direct_pay, :allow_blank => true, :allow_nil => true, :in => DIRECT_PAY_PROVIDERS
  validates_inclusion_of :daily_cap_type, :allow_blank => true, :allow_nil => true, :in => [ :installs, :budget ]
  validates_each :device_types, :allow_blank => false, :allow_nil => false do |record, attribute, value|
    begin
      types = JSON.parse(value)
      record.errors.add(attribute, 'is not an Array') unless types.is_a?(Array)
      record.errors.add(attribute, 'must contain at least one device type') if types.size < 1
      types.each do |type|
        record.errors.add(attribute, 'contains an invalid device type') unless ALL_DEVICES.include?(type)
      end
    rescue
      record.errors.add(attribute, 'is not valid JSON')
    end
  end
  validates_each :approved_sources, :allow_blank => true, :allow_nil => false do |record, attribute, value|
    begin
      types = JSON.parse(value)
      record.errors.add(attribute, 'is not an Array') unless types.is_a?(Array)
      types.each do |type|
        record.errors.add(attribute, "contains an invalid source: #{value}") unless ALL_SOURCES.include?(type)
      end
    rescue
      record.errors.add(attribute, 'is not valid JSON')
    end
  end
  validates :publisher_app_whitelist, :id_list => {:of => App}, :allow_blank => true
  validates_each :payment_range_low do |record, attribute, value|
    if record.payment_range_low.present?
      record.errors.add(attribute, "must equal payment") if value != record.payment
    end
  end
  validates_each :payment_range_high do |record, attribute, value|
    if record.payment_range_low.present?
      record.errors.add(attribute, "must be greater than payment_range_low") if value.blank? || value <= record.payment_range_low
    else
      record.errors.add(attribute, "must not be set if low payment range is not set") if value.present?
    end
  end
  validates_each :multi_complete do |record, attribute, value|
    if value
      record.errors.add(attribute, "is not for App offers, Action offers, or Survey offers") unless record.multi_completable?
      record.errors.add(attribute, "cannot be used for non-interval pay-per-click offers") if record.pay_per_click? && record.interval == 0
    end
  end
  validates_each :instructions_overridden, :if => :instructions_overridden? do |record, attribute, value|
    record.errors.add(attribute, "is only for GenericOffers and ActionsOffers") unless record.item_type == 'GenericOffer' || record.item_type == 'ActionOffer'
  end
  validate :bid_within_range
  validate :instructions_needed_for_pay_per_click_on_instruction
  validate :pay_per_click_is_valid
  validates_each :sdkless, :allow_blank => false, :allow_nil => false do |record, attribute, value|
    if value
      record.get_device_types()
      record.errors.add(attribute, "can only be enabled for Android or iOS offers") unless record.get_platform(true) == 'Android'|| record.get_platform(true) == 'iOS'
      record.errors.add(attribute, "cannot be enabled for pay-per-click offers") if record.pay_per_click?
      record.errors.add(attribute, "can only be enabled for 'App' offers") unless record.item_type == 'App'
    end
  end
  validates_each :tapjoy_enabled do |record, attribute, value|
    if value && record.tapjoy_enabled_changed? && record.missing_app_store_id?
      record.errors.add(attribute, "cannot be enabled without valid store id")
    end
  end
  validates :x_partner_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates :x_partner_exclusion_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates_with OfferPrerequisitesValidator

  before_validation :update_payment
  before_validation :set_reseller_from_partner, :on => :create
  before_create :set_stats_aggregation_times
  before_save :cleanup_url
  before_save :fix_country_targeting
  before_save :update_payment
  before_save :update_instructions
  before_save :sync_creative_approval # Must be before_save so auto-approval can happen
  before_save :nullify_banner_creatives
  after_update :lock_survey_offer
  after_update :update_enabled_deeplink_offer_id
  after_save :update_enabled_rating_offer_id
  after_save :update_pending_enable_requests
  after_save :update_tapjoy_sponsored_associated_offers
  after_save :sync_banner_creatives! # NOTE: this should always be the last thing run by the after_save callback chain
  set_callback :cache, :before, :clear_creative_blobs
  set_callback :cache, :before, :update_video_button_tracking_offers
  set_callback :cache_associations, :before, :app_metadata

  EXCLUDED_ENABLED_OFFER_TYPES = %w(RatingOffer DeeplinkOffer ReengagementOffer)
  scope :enabled_by_tapjoy, :conditions => { :tapjoy_enabled => true }
  scope :enabled_by_user, :conditions => { :user_enabled => true }
  scope :with_allowed_types, :conditions => [ 'item_type not in (?)', EXCLUDED_ENABLED_OFFER_TYPES ]
  scope :funded, {
    :joins => :partner,
    :conditions => '(payment > 0 AND partners.balance > payment) OR (payment = 0 AND reward_value > 0)'
  }
  scope :not_tracking, :conditions => { :tracking_for_id => nil }
  def self.enabled_offers
    not_tracking.funded.with_allowed_types.enabled_by_user.enabled_by_tapjoy.scoped(:readonly => false)
  end

  class << self
    alias_method :active, :enabled_offers
  end

  scope :by_name, lambda { |offer_name| { :conditions => ["offers.name LIKE ?", "%#{offer_name}%" ] } }
  scope :by_device, lambda { |platform| { :conditions => ["offers.device_types LIKE ?", "%#{platform}%" ] } }
  scope :for_offer_list, :select => OFFER_LIST_REQUIRED_COLUMNS
  scope :for_display_ads, :conditions => "price = 0 AND conversion_rate >= 0.3 AND ((item_type = 'App' AND CHAR_LENGTH(offers.name) <= 30) OR approved_banner_creatives IS NOT NULL)"
  scope :non_rewarded, :conditions => "NOT rewarded"
  scope :rewarded, :conditions => "rewarded"
  scope :featured, :conditions => { :featured => true }
  scope :apps, :conditions => { :item_type => 'App' }
  scope :free, :conditions => { :price => 0 }
  scope :nonfeatured, :conditions => { :featured => false }
  scope :visible, :conditions => { :hidden => false }
  scope :to_aggregate_hourly_stats, lambda { { :conditions => [ "next_stats_aggregation_time < ?", Time.zone.now ], :select => :id } }
  scope :to_aggregate_daily_stats, lambda { { :conditions => [ "next_daily_stats_aggregation_time < ?", Time.zone.now ], :select => :id } }
  scope :updated_before, lambda { |time| { :conditions => [ "#{quoted_table_name}.updated_at < ?", time ] } }
  scope :app_offers, lambda { |*args|
    only_client_facing = args.empty? ? true : args.first
    item_types = %w(App ActionOffer)
    item_types += %w(RatingOffer ReengagementOffer) unless only_client_facing
    { :conditions => ["item_type IN (?)", item_types] }
  }
  scope :trackable, :conditions => { :item_type => ['VideoOffer', 'ActionOffer','App','VideoOffer','GenericOffer']}
  scope :video_offers, :conditions => { :item_type => 'VideoOffer' }
  scope :coupon_offers, :conditions => { :item_type => 'Coupon' }
  scope :non_video_offers, :conditions => ["item_type != ?", 'VideoOffer']
  scope :tapjoy_sponsored_offer_ids, :conditions => "tapjoy_sponsored = true", :select => "#{Offer.quoted_table_name}.id"
  scope :creative_approval_needed, :conditions => 'banner_creatives != approved_banner_creatives OR (banner_creatives IS NOT NULL AND approved_banner_creatives IS NULL)'
  PAPAYA_OFFER_COLUMNS = "#{Offer.quoted_table_name}.id, #{AppMetadata.quoted_table_name}.papaya_user_count"
  scope :papaya_app_offers, :joins => :app_metadata,
    :conditions => "#{Offer.quoted_table_name}.item_type = 'App' AND #{AppMetadata.quoted_table_name}.papaya_user_count > 0",
    :select => PAPAYA_OFFER_COLUMNS
  scope :papaya_action_offers, :joins => :app_metadata,
    :conditions => "#{Offer.quoted_table_name}.item_type = 'ActionOffer' AND #{AppMetadata.quoted_table_name}.papaya_user_count > 0",
    :select => PAPAYA_OFFER_COLUMNS
  scope :campaigns, group(:item_id)

  delegate :balance, :pending_earnings, :name, :cs_contact_email, :approved_publisher?, :rev_share, :use_server_whitelist?, :to => :partner, :prefix => true
  delegate :name, :id, :formatted_active_gamer_count, :protocol_handler, :to => :app, :prefix => true, :allow_nil => true
  delegate :trigger_action, :protocol_handler, :to => :generic_offer, :prefix => true, :allow_nil => true
  delegate :store_name, :to => :app_metadata, :prefix => true, :allow_nil => true
  delegate :app_id, :to => :action_offer, :prefix => true, :allow_nil => true
  memoize :partner_balance, :partner_use_server_whitelist?, :app_formatted_active_gamer_count, :app_protocol_handler, :app_name, :generic_offer_trigger_action, :generic_offer_protocol_handler, :app_metadata_store_name, :action_offer_app_id

  alias_method :events, :offer_events
  alias_method :random, :rand

  json_set_field :device_types, :screen_layout_sizes, :countries, :dma_codes, :regions,
    :approved_sources, :carriers, :cities, :exclusion_prerequisite_offer_ids

  def pay_per_click?(ppc_type=nil)
    if ppc_type
      pay_per_click == PAY_PER_CLICK_TYPES[ppc_type]
    else
      pay_per_click != PAY_PER_CLICK_TYPES[:non_ppc]
    end
  end

  def ad_name
    self.requires_admin_device? ? "#{self.name} --admin" : self.name
  end

  def clone
    return super if new_record?

    super.tap do |clone|
      # set up banner_creatives to be copied on save
      banner_creatives.each do |size|
        blob = banner_creative_s3_object(size).read
        clone.add_banner_creative(blob, size)
      end
    end
  end

  def clone_and_save!
    new_offer = clone
    new_offer.attributes = { :created_at => nil, :updated_at => nil, :tapjoy_enabled => false, :icon_id_override => nil }
    new_offer.bid = [new_offer.bid, new_offer.min_bid].max

    yield new_offer if block_given?

    transaction do
      new_offer.save!
      new_offer.override_icon!(icon_s3_object.read) if icon_id_override.present?
    end

    new_offer
  end

  def icon_s3_object(size = nil)
    bucket = S3.bucket(BucketNames::TAPJOY)
    bucket.objects["icons/#{size.present? ? size : 'src'}/#{IconHandler.hashed_icon_id(icon_id)}.jpg"]
  end

  def app_offer?(only_client_facing = true)
    item_types = %w(App ActionOffer)
    item_types += %w(RatingOffer ReengagementOffer) unless only_client_facing
    item_types.include?(item_type)
  end

  def app_id
    return nil unless app_offer?(false)
    return item_id if item_type == 'App'
    item.app_id
  end

  def missing_app_store_id?
    app_offer? && !url_overridden? && item.store_id.blank?
  end

  def countries_blacklist
    if app_offer?
      item.get_countries_blacklist || []
    else
      []
    end
  end
  memoize :countries_blacklist

  def all_blacklisted?
    whitelist = get_countries
    whitelist.present? && (whitelist - countries_blacklist).blank?
  end

  #returns subset of attribute with entries matching all props
  def filter_attribute(attribute, props = {})
    send(attribute).reject do |offer|
      props.detect { |prop,val| offer.send(prop) != val }
    end
  end

  # ActiveRecord::Relation for all Offers (excluding this one) with this offer's item ID
  def associated_offers
    o = Offer.scoped.table
    Offer.where(:item_id => item_id).where(o[:id].not_eq(id))
  end

  # Offer that was the first to be created with this Offer's item_id, also matching the specified options
  # Options:
  #   * :featured : Boolean
  #   * :rewarded : Boolean
  def main_for(opts={})
    raise ArgumentError unless opts.keys.include?(:featured) and opts.keys.include?(:rewarded)
    Offer.where(
      :item_id  => item_id,
      :featured => opts[:featured],
      :rewarded => opts[:rewarded]
    ).order(:created_at).first
  end

  # Offer that was the first to be created with this Offer's:
  #   * item_id
  #   * featured status
  #   * rewarded status
  def main
    @main ||= main_for(:featured => featured?, :rewarded => rewarded?)
  end

  # true if this is the main offer
  def main?
    return @is_main unless @is_main.nil?
    @is_main = (self == self.main)
  end

  # ActiveRecord::Relation for related non-main offers that share the same "featured" and "rewarded" status as this one
  def filtered_associated_offers
    associated_offers.where(:featured => featured?, :rewarded => rewarded?)
  end

  # ActiveRecord::Relation for filtered associated offers that are tapjoy enabled.
  def tapjoy_enabled_filtered_associated_offers
    filtered_associated_offers.where(:tapjoy_enabled => true)
  end

  # ActiveRecord::Relation for filtered associated offers thet are tapjoy disabled ("Deleted").
  def tapjoy_disabled_filtered_associated_offers
    filtered_associated_offers.where(:tapjoy_enabled => false)
  end

  def integrated?
    options = {
      :end_time => Time.zone.now,
      :start_time => Time.zone.now.beginning_of_hour - 23.hours,
      :granularity => :hourly,
      :stat_types => [ 'logins' ]
    }
    Appstats.new(item.id, options).stats['logins'].sum > 0
  end

  def is_publisher_offer?
    item_type == 'App' && (item.primary_currency.present? || item.non_rewarded.present?)
  end

  def primary_offer_enabled?
    Offer.enabled_offers.find_by_id(item_id).present?
  end

  def primary?
    item_id == id
  end

  def is_coupon?
    item_type == 'Coupon'
  end

  def send_low_conversion_email?
    primary? || !primary_offer_enabled?
  end

  def calculate_min_conversion_rate
    min_cvr = min_conversion_rate
    if min_cvr.nil?
      if is_free?
        min_cvr = rewarded? ? 0.12 : 0.01
      else
        min_cvr = item_type == 'GenericOffer' ? 0.002 : 0.005
      end
    end
    min_cvr
  end

  def cost
    price > 0 ? 'Paid' : 'Free'
  end

  def is_paid?
    price > 0
  end
  alias_method :paid?, :is_paid?

  def is_free?
    !is_paid?
  end
  alias_method :free?, :is_free?

  def user_bid_warning
    is_paid? ? price / 100.0 : 1
  end

  def user_bid_max
    [is_paid? ? 5 * price / 100.0 : 3, bid / 100.0].max
  end

  def tapjoy_disable!
    self.tapjoy_enabled = false
    self.save
  end

  def system_enabled?
    tapjoy_enabled? && user_enabled?
  end

  def payment_enabled?
    payment > 0 && partner_balance > 0
  end

  def reward_enabled?
    payment == 0 && reward_value.present? && reward_value > 0
  end

  def tracking_enabled?
    tapjoy_enabled?
  end

  def enabled?
    enabled = system_enabled?
    enabled = (payment_enabled? || reward_enabled? || self_promote_only?) if enabled && !is_deeplink?
    enabled
  end
  alias_method :is_enabled?, :enabled?

  def disabled?; !enabled?; end

  def can_be_promoted?
    primary? && rewarded? && enabled?
  end

  def accepting_clicks?
    tapjoy_enabled? && user_enabled? && (payment > 0 || (payment == 0 && reward_value.present? && reward_value > 0))
  end

  def has_variable_payment?
    payment_range_low.present? && payment_range_high.present?
  end

  def virtual_goods
    VirtualGood.select(:where => "app_id = '#{self.item_id}'")[:items]
  end

  def has_virtual_goods?
    VirtualGood.count(:where => "app_id = '#{self.item_id}'") > 0
  end

  def video_offer?
    item_type == 'VideoOffer'
  end

  def has_adjustable_bid?
    item_type != 'OfferpalOffer' && item_type != 'RatingOffer'
  end

  def coupon_offer?
    item_type == 'Coupon'
  end

  def survey_offer?
    item_type == 'SurveyOffer'
  end

  def show_in_active_campaigns?
    # This logic is duplicated in DashboardController#current_partner_active_offers_relation in an ARel-friendly way.
    item_type =~ /(VideoOffer|App|GenericOffer|ActionOffer|Coupon|SurveyOffer)/
  end

  def video_icon_url(options = {})
    if video_offer? || item_type == 'TestVideoOffer'
      object = S3.bucket(BucketNames::TAPJOY).objects["icons/src/#{IconHandler.hashed_icon_id(icon_id)}.jpg"]
      begin
        object.exists? ? get_icon_url({:source => :cloudfront}.merge(options)) : "#{CLOUDFRONT_URL}/videos/assets/default.png"
      rescue AWS::Errors::Base
        "#{CLOUDFRONT_URL}/videos/assets/default.png"
      end
    end
  end
  memoize :video_icon_url

  def get_icon_url(options = {})
    IconHandler.get_icon_url({:icon_id => IconHandler.hashed_icon_id(icon_id), :item_type => item_type}.merge(options))
  end

  def remove_overridden_icon!
    guid = icon_id

    # only allow removing of offer-specific, manually-uploaded icons
    return if icon_id_override.nil? || [item_id, app_metadata_id, app_id].include?(guid)

    IconHandler.remove_icon!(guid, (item_type == 'VideoOffer'))

    icon_id_override = item_type == 'App' ? nil : app_id # for "app offers" set this back to its default value
    self.update_attributes!(:icon_id_override => icon_id_override)
  end

  def override_icon!(icon_src_blob)
    # Here's how this works...
    # When an offer's icon is requested, it will use the 'icon_id' method,
    # which uses (icon_id_override || app_metadata_id || item_id)
    # as the guid to be passed into IconHandler.hashed_icon_id()
    #
    # Since icon_id_override is normally nil, what this allows for is one icon file to be shared
    # between offers with the same parent (app_metadata or item).
    #
    # This method will set (or utilize the existing) icon_id_override
    #
    # If an individual offer's icon is overridden via this method, then removed via remove_overridden_icon!,
    # the icon shown will fall back to the shared file
    replacing = ![item_id, app_metadata_id, app_id].include?(icon_id_override) && icon_id_override.present?
    guid = replacing ? icon_id_override : UUIDTools::UUID.random_create.to_s
    IconHandler.upload_icon!(icon_src_blob, guid, (item_type == 'VideoOffer'))
    unless replacing
      self.update_attributes!(:icon_id_override => guid, :auto_update_icon => default_auto_update_icon_value)
    end
  end

  def save(*)
    super
  rescue BannerSyncError => bse
    self.errors.add(bse.offer_attr_name.to_sym, bse.message) if bse.offer_attr_name.present?
    false
  end

  def save_video!(video_src_blob)
    bucket = S3.bucket(BucketNames::TAPJOY)

    object = bucket.objects["videos/src/#{id}.mp4"]
    existing_video_blob = object.exists? ? object.read : ''

    return if Digest::MD5.hexdigest(video_src_blob) == Digest::MD5.hexdigest(existing_video_blob)

    object.write(:data => video_src_blob, :acl => :public_read)
  end

  def expected_device_types
    if item_type == 'App' || item_type == 'ActionOffer' || item_type == 'RatingOffer'
      item.get_offer_device_types
    else
      ALL_DEVICES
    end
  end

  def get_publisher_app_whitelist
    Set.new(publisher_app_whitelist.split(';'))
  end
  memoize :get_publisher_app_whitelist

  def get_x_partner_prerequisites
    Set.new(x_partner_prerequisites.split(';'))
  end
  memoize :get_x_partner_prerequisites

  def get_x_partner_exclusion_prerequisites
    Set.new(x_partner_exclusion_prerequisites.split(';'))
  end
  memoize :get_x_partner_exclusion_prerequisites

  def get_platform
    types = get_device_types
    if types.any?{|type| type == 'android' || type == 'windows'}
      types.length == 1 ? App::PLATFORMS[types.first] :  'All'
    else
      'iOS'
    end
  end
  memoize :get_platform

  def wrong_platform?
    if ['App', 'ActionOffer'].include?(item_type)
      App::PLATFORMS.key(get_platform) != item.platform
    end
  end

  def categories
    if item_type == 'App'
      item.categories
    elsif item_type == 'ActionOffer'
      item.app.categories
    else
      []
    end
  end
  memoize :categories

  def name_with_suffix
    name_suffix.blank? ? name : "#{name} -- #{name_suffix}"
  end

  def name_with_suffix_and_platform
    "#{name_with_suffix} (#{get_platform})"
  end

  def truncated_name
    name[0, 40].strip
  end

  def search_result_name
    search_name = name_with_suffix
    search_name += " (active)" if accepting_clicks?
    search_name += " (hidden)" if hidden?
    search_name
  end

  def descriptors
    return @descriptors unless @descriptors.nil?
    @descriptors = []
    @descriptors << (main? ? 'main' : 'associated')
    @descriptors << (rewarded? ? 'rewarded' : 'non-rewarded')
    @descriptors << 'featured' if featured?
    @descriptors << item_type.gsub('Offer', '').downcase unless item_type == 'App'
    @descriptors << 'disabled' unless enabled?
    @descriptors << 'active'   if accepting_clicks?
    @descriptors << 'hidden'   if hidden?
    @descriptors << item.platform if item_type == 'App'
    @descriptors
  end

  def description
    descriptors.join(', ')
  end

  def store_id_for_feed
    store_id = third_party_data if (item_type == 'App')
    store_id || IconHandler.hashed_icon_id(id)
  end

  def uploaded_icon?
    bucket = AWS::S3.new.buckets[BucketNames::TAPJOY]
    bucket.objects["icons/src/#{IconHandler.hashed_icon_id(icon_id)}.jpg"].exists?
  end

  def update_payment(force_update = false)
    if partner && (force_update || bid_changed? || new_record?)
      if partner.discount_all_offer_types? || app_offer?
        self.payment = bid == 0 ? 0 : [ bid * (100 - partner.premier_discount) / 100, 1 ].max
      else
        self.payment = bid
      end
    end
  end

  def update_payment!
    update_payment(true)
    save!
  end

  def min_bid
    min_bid_override || calculated_min_bid
  end

  def max_bid
    val = item_type == 'GenericOffer' ? 15000 : 10000
    [ val, (price * 0.50).round ].max
  end

  def create_non_rewarded_featured_clone
    create_clone :featured => true, :rewarded => false
  end

  def create_rewarded_featured_clone
    create_clone :featured => true, :rewarded => true
  end

  def create_non_rewarded_clone
    create_clone :featured => false, :rewarded => false
  end

  def needs_more_funds?
    show_rate != 1 && (unlimited_budget? || low_balance?)
  end

  def no_daily_budget?; daily_budget.zero?; end
  def has_daily_budget?; daily_budget > 0; end
  def no_overall_budget?; overall_budget.zero?; end
  def has_overall_budget?; overall_budget > 0; end

  def low_daily_budget?
    has_daily_budget? && daily_budget < 5000
  end

  def over_daily_budget?(num_installs_today)
    has_daily_budget? && num_installs_today > daily_budget
  end

  def unlimited_budget?
    no_daily_budget? && no_overall_budget?
  end

  def icon_id
    icon_id_override || app_metadata_id || item_id
  end

  def expensive?
    price > 299
  end

  def can_request_enable?
    item_type == 'App' ? item.store_id.present? : true
  end

  def has_contacts?
    !partner.users.empty?
  end

  def contacts
    partner.non_managers
  end

  def account_managers
    partner.account_managers
  end

  def internal_notes
    partner.account_manager_notes
  end

  def toggle_user_enabled
    self.user_enabled = !user_enabled
  end

  def calculate_rank_boost!
    update_attribute(:rank_boost, rank_boosts.active.not_optimized.sum(:amount))
  end

  def calculate_optimized_rank_boost!
    update_attribute(:optimized_rank_boost, rank_boosts.active.optimized.sum(:amount))
  end

  def set_reseller_from_partner
    self.reseller_id = partner.reseller_id if partner_id?
  end

  def unlogged_attributes
    [ 'normal_avg_revenue', 'normal_bid', 'normal_conversion_rate', 'normal_price' ]
  end

  def to_s
    name
  end

  def num_support_requests(start_time = 1.day.ago, end_time = Time.zone.now)
    Mc.get_and_put("offer.support_requests.#{id}", false, 1.hour) do
      conditions = [
        "offer_id = '#{id}'",
        "`updated-at` < '#{end_time.to_f}'",
        "`updated-at` >= '#{start_time.to_f}'",
      ].join(' and ')
      SupportRequest.count(:where => conditions)
    end
  end

  def num_clicks_rewarded(start_time = 1.day.ago, end_time = Time.zone.now)
    Mc.get_and_put("offer.clicks_rewarded.#{id}", false, 1.hour) do
      clicks_rewarded = 0
      conditions = [
        "offer_id = '#{id}'",
        "clicked_at < '#{end_time.to_f}'",
        "clicked_at >= '#{start_time.to_f}'",
        "installed_at is not null",
      ].join(' and ')
      Click.count(:where => conditions)
    end
  end

  def promotion_platform
    self.app ?  self.app.platform.to_sym : nil
  end
  memoize :promotion_platform

  def calculate_target_installs(num_installs_today)
    target_installs = 1.0 / 0
    target_installs = daily_budget - num_installs_today if daily_budget > 0

    unless allow_negative_balance? || self_promote_only?
      adjusted_balance = partner.balance
      if is_free? && adjusted_balance < 50000
        adjusted_balance = adjusted_balance / 2
      end

      max_paid_installs = adjusted_balance / payment
      target_installs = max_paid_installs if target_installs > max_paid_installs
    end

    target_installs
  end

  def cached_support_requests_rewards
    support_requests = Mc.get("offer.support_requests.#{id}")
    rewards = Mc.get("offer.clicks_rewarded.#{id}")
    [ support_requests, rewards ]
  end

  def multi_completable?
    !%w(App ActionOffer SurveyOffer).include?(item_type) || Offer::Rejecting::TAPJOY_GAMES_RETARGETED_OFFERS.include?(item_id)
  end

  def video_button_tracking_offers
    @video_button_tracking_offers || []
  end

  def update_video_button_tracking_offers
    return unless video_offer?
    @video_button_tracking_offers = item.video_buttons.enabled.ordered.collect(&:tracking_offer).compact
  end

  def is_deeplink?
    item_type == 'DeeplinkOffer'
  end

  # We want a consistent "app id" to report to partners/3rd parties,
  # but we don't want to reveal internal IDs. We also want to make
  # the values unique between partners so that no 'collusion' can
  # take place.
  def source_token(publisher_app_id)
    ObjectEncryptor.encrypt("#{publisher_app_id}.#{partner_id}")
  end

  def initialize_from_app(app)
    self.name         = app.name
    self.price        = 0
    self.bid          = min_bid
    self.url          = app.store_url
    self.device_types = app.get_offer_device_types.to_json
  end

  def initialize_from_app_metadata(app_metadata, default_name = 'untitled')
    self.app_metadata     = app_metadata
    self.name             = app_metadata.name ? app_metadata.name : default_name # validated as non-nil, will be updated when app metadata name is fetched from store
    self.price            = app_metadata.price
    self.bid              = min_bid
    self.url              = app_metadata.store_url
    self.device_types     = app_metadata.get_offer_device_types.to_json
    self.third_party_data = app_metadata.store_id
    self.age_rating       = app_metadata.age_rating
    self.wifi_only        = app_metadata.wifi_required?
  end

  def update_from_app_metadata(app_metadata, default_name = 'untitled')
    if item_type == 'App'
      if self.app_metadata == app_metadata
        self.name = app_metadata.name if app_metadata.name_changed? && ( app_metadata.name_was == self.name || app_metadata.name_was.nil? )
      else
        self.app_metadata = app_metadata
        self.name = app_metadata.name
        self.third_party_data = app_metadata.store_id
        self.device_types = app_metadata.get_offer_device_types.to_json
        self.url = app_metadata.store_url unless url_overridden?
      end
      self.name = default_name if self.name.nil?
      self.price = app_metadata.price
      self.bid = min_bid if bid < min_bid
      self.bid = max_bid if bid > max_bid
      self.age_rating = app_metadata.age_rating
      self.wifi_only = app_metadata.wifi_required?
    elsif item_type == 'ActionOffer'
      self.url           = app_metadata.store_url unless url_overridden?
      self.price         = action_offer.offer_price(app_metadata)
      if price_changed? && bid < min_bid
        self.bid        = min_bid
      end
      self.app_metadata = app_metadata
    end
    self.save! if self.changed?
  end

  def get_disabled_reasons
    reasons = []
    reasons << 'Tapjoy Disabled' unless self.tapjoy_enabled
    reasons << 'User Disabled' unless self.user_enabled
    reasons << 'Payment below balance' if self.payment > 0 && partner.balance <= self.payment && !self.is_deeplink? && !self_promote_only?
    reasons << 'Tracking for' unless self.tracking_for.nil?

    reasons
  end

  def build_tracking_offer_for(tracked_for, options = {})
    options.merge!({ :app_metadata => app_metadata, :source_offer_id => id })
    item.build_tracking_offer_for(tracked_for, options)
  end

  def find_tracking_offer_for(tracked_for)
    tracking_offer = item.find_tracking_offer_for(tracked_for)
    options = { :app_metadata => app_metadata, :source_offer_id => id }
    options.merge!(item.tracking_offer_options(tracked_for)).merge!(tracked_for.tracking_item_options(self) || {})
    tracking_offer.attributes=(options) if tracking_offer
    tracking_offer
  end

  def display_ad_image_hash(currency)
    currency_string = "#{currency.get_visual_reward_amount(self)}.#{currency.name}" if currency.present?
    Digest::MD5.hexdigest("#{currency_string}.#{name}.#{IconHandler.hashed_icon_id(icon_id)}")
  end

  def featured_ad_color_in_css
    featured_ad_color || DEFAULT_FEATURED_AD_BACKGROUND
  end

  def age_gate?
    video_offer? && age_rating
  end

  def daily_cap_type
    value = read_attribute(:daily_cap_type)
    value.blank? ? nil : value.to_sym
  end

  def daily_cap_type=(value)
    write_attribute(:daily_cap_type, value.blank? ? nil : value.to_sym)
  end

  def has_instructions?
    is_coupon? || (item_type != 'VideoOffer' && instructions.present?)
  end

  def should_notify_on_conversion?
    !(video_offer? || survey_offer?)
  end

  def auditioning
    @auditioning || false
  end

  private

  def calculated_min_bid
    if item_type == 'App'
      if featured? && rewarded?
        is_paid? ? price : 10
      elsif !rewarded?
        100
      else
        is_paid? ? (price * 0.50).round : 10
      end
    elsif item_type == 'ActionOffer' || is_coupon?
      is_paid? ? (price * 0.50).round : 10
    elsif video_offer?
      2
    else
      0
    end
  end

  def default_auto_update_icon_value
    app_offer?(false) || item_type == 'DeeplinkOffer' # TODO: add DeeplinkOffer to app_offer? method
  end

  def cleanup_url
    if (url_overridden_changed? || url_changed?) && !url_overridden?
      if %w(App ActionOffer).include?(item_type) && app_metadata
        self.url = app_metadata.store_url
      elsif %w(App ActionOffer RatingOffer).include?(item_type)
        self.url = self.item.store_url
      elsif item_type == 'GenericOffer'
        self.url = self.item.url
      end
    end
    self.url = url.gsub(" ", "%20")
  end

  def set_stats_aggregation_times
    now = Time.now.utc
    self.last_stats_aggregation_time       = nil
    self.last_daily_stats_aggregation_time = nil
    self.next_stats_aggregation_time       = now
    self.next_daily_stats_aggregation_time = (now + 1.day).beginning_of_day + StatsAggregation::DAILY_STATS_START_HOUR.hours
  end

  def instructions_needed_for_pay_per_click_on_instruction
    if pay_per_click?(:ppc_on_instruction) && instructions.blank?
      errors.add :pay_per_click, "needs instructions if set to pay-per-click on instruction page"
    end
  end

  def pay_per_click_is_valid
    if item_type == "RatingOffer" || item_type == "DeeplinkOffer"
      errors.add :pay_per_click, "must not be Non Pay-per-click" unless pay_per_click?
    elsif is_coupon? || item_type == "SurveyOffer"
      errors.add :pay_per_click, "must be Non Pay-per-click" if pay_per_click?
    end
  end

  def bid_within_range
    if bid_changed? || price_changed?
      if bid < min_bid
        errors.add :bid, "is below the minimum (#{min_bid} cents)"
      end
      if bid > max_bid
        errors.add :bid, "is above the maximum (#{max_bid} cents)"
      end
      if item_type == 'RatingOffer' && bid != 0
        errors.add :bid, "must be 0 for RatingOffers"
      end
    end
  end

  def update_enabled_rating_offer_id
    if item_type == 'RatingOffer' && (tapjoy_enabled_changed? || user_enabled_changed? || reward_value_changed? || payment_changed?)
      item.app.enabled_rating_offer_id = accepting_clicks? ? id : nil
      item.app.save! if item.app.changed?
    end
  end

  def update_enabled_deeplink_offer_id
    if is_deeplink? && (tapjoy_enabled_changed? || user_enabled_changed? || reward_value_changed? || payment_changed?)
      item.currency.enabled_deeplink_offer_id = accepting_clicks? ? id : nil
      item.currency.save! if item.currency.changed?
    end
  end

  def update_pending_enable_requests
    if tapjoy_enabled_changed? && tapjoy_enabled?
      enable_offer_requests.pending.each { |request| request.approve! }
    elsif hidden_changed? && hidden?
      enable_offer_requests.pending.each { |request| request.approve!(false) }
    end
  end

  def update_tapjoy_sponsored_associated_offers
    if tapjoy_sponsored_changed?
      associated_offers.each do |o|
        o.tapjoy_sponsored = tapjoy_sponsored
        o.save! if o.changed?
      end
    end
  end

  def fix_country_targeting
    unless countries.blank?
      countries.gsub!(/uk/i, 'GB')
    end
  end

  def update_instructions
    if instructions_overridden_changed? && !instructions_overridden? && (item_type == 'ActionOffer' || item_type == 'GenericOffer')
      self.instructions = item.instructions
    end
  end

  def create_clone(options = {})
    featured = options[:featured]
    rewarded = options[:rewarded]

    clone_and_save! do |new_offer|
      new_offer.attributes = {
        :featured    => !featured.nil? ? featured : self.featured,
        :rewarded    => !rewarded.nil? ? rewarded : self.rewarded
      }
      new_offer.bid = new_offer.min_bid
    end
  end

  def lock_survey_offer
    if item_type == 'SurveyOffer' && (tapjoy_enabled_changed? || user_enabled_changed?)
      if tapjoy_enabled? && user_enabled? && !item.locked?
        item.update_attribute(:locked, true)
      end
    end
  end
end
