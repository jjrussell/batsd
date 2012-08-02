class Offer < ActiveRecord::Base
  include ActiveModel::Validations
  include UuidPrimaryKey
  include Offer::Ranking
  include Offer::Rejecting
  include Offer::UrlGeneration
  include Offer::BannerCreatives
  include Offer::ThirdPartyTracking
  include Offer::Optimization
  include Offer::ShowRateAlgorithms
  acts_as_cacheable
  acts_as_tracking
  memoize :precache_rank_scores

  APPLE_DEVICES = %w( iphone itouch ipad )
  IPAD_DEVICES = %w( ipad )
  ANDROID_DEVICES = %w( android )
  WINDOWS_DEVICES = %w( windows )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES + WINDOWS_DEVICES
  ALL_OFFER_TYPES = %w( App EmailOffer GenericOffer OfferpalOffer RatingOffer ActionOffer VideoOffer SurveyOffer ReengagementOffer DeeplinkOffer)
  REWARDED_APP_INSTALL_OFFER_TYPES = Set.new(%w( App EmailOffer OfferpalOffer RatingOffer ActionOffer ReengagementOffer DeeplinkOffer))
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

  OFFER_LIST_EXCLUDED_COLUMNS = %w( account_manager_notes
                                    active
                                    allow_negative_balance
                                    created_at
                                    daily_budget
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
                                    stats_aggregation_interval
                                    tapjoy_enabled
                                    tapjoy_sponsored
                                    updated_at
                                    url_overridden
                                    user_enabled
                                    tracking_for_id
                                    tracking_for_type )

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

  attr_reader :video_button_tracking_offers

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
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  validates_presence_of :reseller, :if => Proc.new { |offer| offer.reseller_id? }
  validates_presence_of :partner, :item, :name, :url, :rank_boost
  validates_presence_of :prerequisite_offer, :if => Proc.new { |offer| offer.prerequisite_offer_id? }
  validates_numericality_of :price, :interval, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :bid, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :min_bid_override, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :rank_boost, :allow_nil => false, :only_integer => true
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :self_promote_only, :featured, :multi_complete, :rewarded, :cookie_tracking, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => ALL_OFFER_TYPES
  validates_inclusion_of :direct_pay, :allow_blank => true, :allow_nil => true, :in => DIRECT_PAY_PROVIDERS
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
  after_save :update_enabled_rating_offer_id
  after_save :update_enabled_deeplink_offer_id
  after_save :update_pending_enable_requests
  after_save :update_tapjoy_sponsored_associated_offers
  after_save :sync_banner_creatives! # NOTE: this should always be the last thing run by the after_save callback chain
  set_callback :cache, :before, :clear_creative_blobs
  set_callback :cache, :before, :update_video_button_tracking_offers

  ENABLED_OFFER_TYPES = %w(RatingOffer DeeplinkOffer ReengagementOffer)
  scope :enabled_by_tapjoy, :conditions => { :tapjoy_enabled => true }
  scope :enabled_by_user, :conditions => { :user_enabled => true }
  scope :with_allowed_types, :conditions => [ 'item_type not in (?)', ENABLED_OFFER_TYPES ]
  scope :with_fund, {
    :joins => :partner,
    :conditions => '(payment > 0 AND partners.balance > payment) OR (payment = 0 AND reward_value > 0)'
  }
  scope :not_tracking, :conditions => { :tracking_for_id => nil }
  def self.enabled_offers
    not_tracking.with_fund.with_allowed_types.enabled_by_user.enabled_by_tapjoy.scoped(:readonly => false)
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
  scope :app_offers, :conditions => "item_type = 'App' or item_type = 'ActionOffer'"
  scope :video_offers, :conditions => { :item_type => 'VideoOffer' }
  scope :non_video_offers, :conditions => ["item_type != ?", 'VideoOffer']
  scope :tapjoy_sponsored_offer_ids, :conditions => "tapjoy_sponsored = true", :select => "#{Offer.quoted_table_name}.id"
  scope :creative_approval_needed, :conditions => 'banner_creatives != approved_banner_creatives OR (banner_creatives IS NOT NULL AND approved_banner_creatives IS NULL)'

  PAPAYA_OFFER_COLUMNS = "#{Offer.quoted_table_name}.id, #{AppMetadata.quoted_table_name}.papaya_user_count"
  #TODO: simplify these named scopes when support for multiple appstores is complete and offer includes app_metadata_id
  scope :papaya_app_offers,
    :joins => "inner join #{AppMetadataMapping.quoted_table_name} on #{Offer.quoted_table_name}.item_id = #{AppMetadataMapping.quoted_table_name}.app_id
      inner join #{AppMetadata.quoted_table_name} on #{AppMetadataMapping.quoted_table_name}.app_metadata_id = #{AppMetadata.quoted_table_name}.id",
    :conditions => "#{Offer.quoted_table_name}.item_type = 'App' AND #{AppMetadata.quoted_table_name}.papaya_user_count > 0",
    :select => PAPAYA_OFFER_COLUMNS
  scope :papaya_action_offers,
    :joins => "inner join #{ActionOffer.quoted_table_name} on #{Offer.quoted_table_name}.item_id = #{ActionOffer.quoted_table_name}.id
      inner join #{AppMetadataMapping.quoted_table_name} on #{ActionOffer.quoted_table_name}.app_id = #{AppMetadataMapping.quoted_table_name}.app_id
      inner join #{AppMetadata.quoted_table_name} on #{AppMetadataMapping.quoted_table_name}.app_metadata_id = #{AppMetadata.quoted_table_name}.id",
    :conditions => "#{Offer.quoted_table_name}.item_type = 'ActionOffer' AND #{AppMetadata.quoted_table_name}.papaya_user_count > 0",
    :select => PAPAYA_OFFER_COLUMNS

  delegate :balance, :pending_earnings, :name, :cs_contact_email, :approved_publisher?, :rev_share, :use_server_whitelist?, :to => :partner, :prefix => true
  delegate :name, :id, :formatted_active_gamer_count, :protocol_handler, :to => :app, :prefix => true, :allow_nil => true
  delegate :trigger_action, :protocol_handler, :to => :generic_offer, :prefix => true, :allow_nil => true
  memoize :partner_balance, :partner_use_server_whitelist?, :app_formatted_active_gamer_count, :app_protocol_handler, :app_name, :generic_offer_trigger_action, :generic_offer_protocol_handler

  alias_method :events, :offer_events
  alias_method :random, :rand

  json_set_field :device_types, :screen_layout_sizes, :countries, :dma_codes, :regions,
    :approved_sources, :carriers, :cities, :exclusion_prerequisite_offer_ids

  def clone
    return super if new_record?

    super.tap do |clone|
      # set up banner_creatives to be copied on save
      banner_creatives.each do |size|
        blob = banner_creative_s3_object(size).read
        clone.send("banner_creative_#{size}_blob=", blob)
      end
    end
  end

  def app_offer?
    item_type == 'App' || item_type == 'ActionOffer'
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

  def find_associated_offers
    Offer.find(:all, :conditions => ["item_id = ? and id != ?", item_id, id])
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
    item_type == 'App' && item.primary_currency.present?
  end

  def primary_offer_enabled?
    Offer.enabled_offers.find_by_id(item_id).present?
  end

  def primary?
    item_id == id
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

  def is_free?
    !is_paid?
  end

  def user_bid_warning
    is_paid? ? price / 100.0 : 1
  end

  def user_bid_max
    [is_paid? ? 5 * price / 100.0 : 3, bid / 100.0].max
  end

  def is_enabled?
    tapjoy_enabled? && user_enabled? && ((payment > 0 && partner_balance > 0) || (payment == 0 && reward_value.present? && reward_value > 0))
  end

  def can_be_promoted?
    primary? && rewarded? && is_enabled?
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

  def show_in_active_campaigns?
    item_type == 'VideoOffer' || item_type == 'App' || item_type == 'GenericOffer' || item_type == 'ActionOffer'
  end

  def video_icon_url(options = {})
    if video_offer? || item_type == 'TestVideoOffer'
      object = S3.bucket(BucketNames::TAPJOY).objects["icons/src/#{Offer.hashed_icon_id(icon_id)}.jpg"]
      begin
        object.exists? ? get_icon_url({:source => :cloudfront}.merge(options)) : "#{CLOUDFRONT_URL}/videos/assets/default.png"
      rescue AWS::Errors::Base
        "#{CLOUDFRONT_URL}/videos/assets/default.png"
      end
    end
  end
  memoize :video_icon_url

  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(icon_id), :item_type => item_type}.merge(options))
  end

  def self.get_icon_url(options = {})
    source     = options.delete(:source)   { :s3 }
    icon_id    = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
    item_type  = options.delete(:item_type)
    size       = options.delete(:size)     { (item_type == 'VideoOffer' || item_type == 'TestVideoOffer') ? '200' : '57' }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL

    "#{prefix}/icons/#{size}/#{icon_id}.jpg"
  end

  def save_icon!(icon_src_blob)
    icon_id = Offer.hashed_icon_id(id)
    bucket  = S3.bucket(BucketNames::TAPJOY)
    src_obj = bucket.objects["icons/src/#{icon_id}.jpg"]

    existing_icon_blob = src_obj.exists? ? src_obj.read : ''

    return if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)

    if video_offer?
      icon_200 = Magick::Image.from_blob(icon_src_blob)[0].resize(200, 125).opaque('#ffffff00', 'white')
      corner_mask_blob = bucket.objects["display/round_mask_200x125.png"].read
      corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(200, 125)
      icon_200.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
      icon_200 = icon_200.opaque('#ffffff00', 'white')
      icon_200.alpha(Magick::OpaqueAlphaChannel)

      icon_200_blob = icon_200.to_blob{|i| i.format = 'JPG'}
      bucket.objects["icons/200/#{icon_id}.jpg"].write(:data => icon_200_blob, :acl => :public_read)
      src_obj.write(:data => icon_src_blob, :acl => :public_read)

      Mc.delete("icon.s3.#{id}")
      paths = ["icons/200/#{icon_id}.jpg"]
      CloudFront.invalidate(id, paths) if existing_icon_blob.present?
      return
    end

    icon_256 = Magick::Image.from_blob(icon_src_blob)[0].resize(256, 256).opaque('#ffffff00', 'white')

    corner_mask_blob = bucket.objects["display/round_mask.png"].read
    corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(256, 256)
    icon_256.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
    icon_256 = icon_256.opaque('#ffffff00', 'white')
    icon_256.alpha(Magick::OpaqueAlphaChannel)

    icon_256_blob = icon_256.to_blob{|i| i.format = 'JPG'}
    icon_114_blob = icon_256.resize(114, 114).to_blob{|i| i.format = 'JPG'}
    icon_57_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'JPG'}
    icon_57_png_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'PNG'}

    bucket.objects["icons/256/#{icon_id}.jpg"].write(:data => icon_256_blob, :acl => :public_read)
    bucket.objects["icons/114/#{icon_id}.jpg"].write(:data => icon_114_blob, :acl => :public_read)
    bucket.objects["icons/57/#{icon_id}.jpg"].write(:data => icon_57_blob, :acl => :public_read)
    bucket.objects["icons/57/#{icon_id}.png"].write(:data => icon_57_png_blob, :acl => :public_read)
    src_obj.write(:data => icon_src_blob, :acl => :public_read)

    Mc.delete("icon.s3.#{id}")
    paths = ["icons/256/#{icon_id}.jpg", "icons/114/#{icon_id}.jpg", "icons/57/#{icon_id}.jpg", "icons/57/#{icon_id}.png"]
    CloudFront.invalidate(id, paths) if existing_icon_blob.present?

    if item_type == 'App' && app.present? && app.primary_app_metadata.present?
      app_metadata_id = app.primary_app_metadata.id
      meta_icon_id = Offer.hashed_icon_id(app_metadata_id)
      meta_src_icon_obj = bucket.objects["icons/src/#{meta_icon_id}.jpg"]
      existing_meta_icon_blob = meta_src_icon_obj.exists? ? meta_src_icon_obj.read : ''

      bucket.objects["icons/256/#{icon_id}.jpg"].copy_to(bucket.objects["icons/256/#{meta_icon_id}.jpg"], {:acl => :public_read })
      bucket.objects["icons/114/#{icon_id}.jpg"].copy_to(bucket.objects["icons/114/#{meta_icon_id}.jpg"], {:acl => :public_read })
      bucket.objects["icons/57/#{icon_id}.jpg"].copy_to(bucket.objects["icons/57/#{meta_icon_id}.jpg"], {:acl => :public_read })
      bucket.objects["icons/57/#{icon_id}.png"].copy_to(bucket.objects["icons/57/#{meta_icon_id}.png"], {:acl => :public_read })
      bucket.objects["icons/src/#{icon_id}.jpg"].copy_to(bucket.objects["icons/src/#{meta_icon_id}.jpg"], {:acl => :public_read })

      Mc.delete("icon.s3.#{app_metadata_id}")
      paths = ["icons/256/#{meta_icon_id}.jpg", "icons/114/#{meta_icon_id}.jpg", "icons/57/#{meta_icon_id}.jpg", "icons/57/#{meta_icon_id}.png"]
      CloudFront.invalidate(id, paths) if existing_meta_icon_blob.present?
    end

  end

  def save(perform_validation = true)
    super(:validate => perform_validation)
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

  def store_id_for_feed
    item_type == 'App' ? third_party_data : Offer.hashed_icon_id(id)
  end

  def uploaded_icon?
    bucket = AWS::S3.new.buckets[BucketNames::TAPJOY]
    bucket.objects["icons/src/#{Offer.hashed_icon_id(icon_id)}.jpg"].exists?
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
    icon_id_override || item_id
  end

  def self.hashed_icon_id(guid)
    Digest::SHA2.hexdigest(ICON_HASH_SALT + guid)
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
    update_attribute(:rank_boost, rank_boosts.active.sum(:amount))
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

  # We want a consistent "app id" to report to partners/3rd parties,
  # but we don't want to reveal internal IDs. We also want to make
  # the values unique between partners so that no 'collusion' can
  # take place.
  def source_token(publisher_app_id)
    ObjectEncryptor.encrypt("#{publisher_app_id}.#{partner_id}")
  end

  def get_disabled_reasons
    reasons = []
    reasons << 'Tapjoy Disabled' unless self.tapjoy_enabled
    reasons << 'User Disabled' unless self.user_enabled
    reasons << 'Payment below balance' if self.payment > 0 && partner.balance <= self.payment
    reasons << 'Has a reward value with no Payment' if self.payment == 0 && self.reward_value.to_i > 0
    reasons << 'Tracking for' unless self.tracking_for.nil?

    reasons
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
    elsif item_type == 'ActionOffer'
      is_paid? ? (price * 0.50).round : 10
    elsif video_offer?
      2
    else
      0
    end
  end

  def is_test_device?(currency, device)
    currency.get_test_device_ids.include?(device.id)
  end

  def cleanup_url
    if (url_overridden_changed? || url_changed?) && !url_overridden?
      if %w(App ActionOffer RatingOffer).include?(item_type)
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
    if item_type == 'DeeplinkOffer' && (tapjoy_enabled_changed? || user_enabled_changed? || reward_value_changed? || payment_changed?)
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
      find_associated_offers.each do |o|
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

    offer = self.clone
    offer.attributes = {
      :created_at => nil,
      :updated_at => nil,
      :featured   => !featured.nil? ? featured : self.featured,
      :rewarded   => !rewarded.nil? ? rewarded : self.rewarded,
      :name_suffix => "#{rewarded ? '' : 'non-'}rewarded#{featured ? ' featured': ''}",
      :tapjoy_enabled => false }
    offer.bid = offer.min_bid
    offer.save!
    offer
  end

  def lock_survey_offer
    if item_type == 'SurveyOffer' && (tapjoy_enabled_changed? || user_enabled_changed?)
      if tapjoy_enabled? && user_enabled? && !item.locked?
        item.update_attribute(:locked, true)
      end
    end
  end

end
