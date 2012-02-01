class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  include Offer::Ranking
  include Offer::Rejecting
  include Offer::UrlGeneration
  acts_as_cacheable
  memoize :precache_rank_scores

  APPLE_DEVICES = %w( iphone itouch ipad )
  IPAD_DEVICES = %w( ipad )
  ANDROID_DEVICES = %w( android )
  WINDOWS_DEVICES = %w( windows )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES + WINDOWS_DEVICES
  ALL_OFFER_TYPES = %w( App EmailOffer GenericOffer OfferpalOffer RatingOffer ActionOffer VideoOffer SurveyOffer )
  ALL_SOURCES = %w( offerwall display_ad featured tj_games )

  CLASSIC_OFFER_TYPE               = '0'
  DEFAULT_OFFER_TYPE               = '1'
  FEATURED_OFFER_TYPE              = '2'
  DISPLAY_OFFER_TYPE               = '3'
  NON_REWARDED_DISPLAY_OFFER_TYPE  = '4'
  NON_REWARDED_FEATURED_OFFER_TYPE = '5'
  VIDEO_OFFER_TYPE                 = '6'
  FEATURED_BACKFILLED_OFFER_TYPE   = '7'
  NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE = '8'
  OFFER_TYPE_NAMES = {
    DEFAULT_OFFER_TYPE               => 'Offerwall Offers',
    FEATURED_OFFER_TYPE              => 'Rewarded Featured Offers',
    DISPLAY_OFFER_TYPE               => 'Display Ad Offers',
    NON_REWARDED_DISPLAY_OFFER_TYPE  => 'Non-Rewarded Display Ad Offers',
    NON_REWARDED_FEATURED_OFFER_TYPE => 'Non-Rewarded Featured Offers',
    VIDEO_OFFER_TYPE                 => 'Video Offers',
    FEATURED_BACKFILLED_OFFER_TYPE   => 'Rewarded Featured Offers (Backfilled)',
    NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE => 'Non-Rewarded Featured Offers (Backfilled)'
  }

  DISPLAY_AD_SIZES = ['320x50', '640x100', '768x90'] # data stored as pngs
  FEATURED_AD_SIZES = ['960x640', '640x960', '480x320', '320x480'] # data stored as jpegs
  CUSTOM_AD_SIZES = DISPLAY_AD_SIZES + FEATURED_AD_SIZES

  OFFER_LIST_REQUIRED_COLUMNS = [ 'id', 'item_id', 'item_type', 'partner_id',
                                  'name', 'url', 'price', 'bid', 'payment',
                                  'conversion_rate', 'show_rate', 'self_promote_only',
                                  'device_types', 'countries',
                                  'age_rating', 'multi_complete', 'featured',
                                  'publisher_app_whitelist', 'direct_pay', 'reward_value',
                                  'third_party_data', 'payment_range_low',
                                  'payment_range_high', 'icon_id_override', 'rank_boost',
                                  'normal_bid', 'normal_conversion_rate', 'normal_avg_revenue',
                                  'normal_price', 'over_threshold', 'rewarded', 'reseller_id',
                                  'cookie_tracking', 'min_os_version', 'screen_layout_sizes',
                                  'interval', 'banner_creatives', 'dma_codes', 'regions',
                                  'wifi_only', 'approved_sources', 'approved_banner_creatives'
                                ].map { |c| "#{quoted_table_name}.#{c}" }.join(', ')

  DIRECT_PAY_PROVIDERS = %w( boku paypal )

  FREQUENCIES_CAPPING_INTERVAL = {
    "none"     => 0,
    "1 minute" => 1.minute.to_i,
    "1 hour"   => 1.hour.to_i,
    "8 hours"  => 8.hours.to_i,
    "24 hours" => 24.hours.to_i,
    "2 days"   => 2.days.to_i,
    "3 days"   => 3.days.to_i,
  }

  PAPAYA_OFFER_COLUMNS = "#{Offer.quoted_table_name}.id, #{App.quoted_table_name}.papaya_user_count"

  serialize :banner_creatives, Array
  serialize :approved_banner_creatives, Array

  CUSTOM_AD_SIZES.each do |size|
    attr_accessor "banner_creative_#{size}_blob".to_sym
  end

  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  has_many :rank_boosts
  has_many :enable_offer_requests
  has_many :dependent_action_offers, :class_name => 'ActionOffer', :foreign_key => :prerequisite_offer_id
  has_many :offer_events
  has_many :editors_picks
  has_many :approvals, :class_name => 'CreativeApprovalQueue'

  belongs_to :partner
  belongs_to :item, :polymorphic => true
  belongs_to :reseller
  belongs_to :app, :foreign_key => "item_id", :conditions => ['item_type = ?', 'App']
  belongs_to :action_offer, :foreign_key => "item_id", :conditions => ['item_type = ?', 'ActionOffer']

  validates_presence_of :reseller, :if => Proc.new { |offer| offer.reseller_id? }
  validates_presence_of :partner, :item, :name, :url, :rank_boost
  validates_numericality_of :price, :interval, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :bid, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :min_bid_override, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :rank_boost, :allow_nil => false, :only_integer => true
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :self_promote_only, :featured, :multi_complete, :rewarded, :cookie_tracking, :tj_games_only, :in => [ true, false ]
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
  validates_each :publisher_app_whitelist, :allow_blank => true do |record, attribute, value|
    if record.publisher_app_whitelist_changed?
      value.split(';').each do |app_id|
        record.errors.add(attribute, "contains an unknown app id: #{app_id}") if App.find_by_id(app_id).nil?
      end
    end
  end
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
      record.errors.add(attribute, "is not for App offers") unless record.multi_completable?
      record.errors.add(attribute, "cannot be used for non-interval pay-per-click offers") if record.pay_per_click? && record.interval == 0
    end
  end
  validates_each :instructions_overridden, :if => :instructions_overridden? do |record, attribute, value|
    record.errors.add(attribute, "is only for GenericOffers and ActionsOffers") unless record.item_type == 'GenericOffer' || record.item_type == 'ActionOffer'
  end
  validate :bid_within_range

  before_validation :update_payment
  before_validation_on_create :set_reseller_from_partner
  before_create :set_stats_aggregation_times
  before_save :cleanup_url
  before_save :fix_country_targeting
  before_save :update_payment
  before_save :update_instructions
  before_save :sync_creative_approval # Must be before_save so auto-approval can happen
  after_save :update_enabled_rating_offer_id
  after_save :update_pending_enable_requests
  after_save :update_tapjoy_sponsored_associated_offers
  after_save :sync_banner_creatives! # NOTE: this should always be the last thing run by the after_save callback chain
  before_cache :clear_creative_blobs

  named_scope :enabled_offers, :joins => :partner,
    :readonly => false, :conditions => "tapjoy_enabled = true AND user_enabled = true AND item_type != 'RatingOffer' AND ((payment > 0 AND #{Partner.quoted_table_name}.balance > payment) OR (payment = 0 AND reward_value > 0))"
  named_scope :by_name, lambda { |offer_name| { :conditions => ["offers.name LIKE ?", "%#{offer_name}%" ] } }
  named_scope :by_device, lambda { |platform| { :conditions => ["offers.device_types LIKE ?", "%#{platform}%" ] } }
  named_scope :for_offer_list, :select => OFFER_LIST_REQUIRED_COLUMNS
  named_scope :for_display_ads, :conditions => "item_type = 'App' AND price = 0 AND conversion_rate >= 0.3 AND LENGTH(offers.name) <= 30"
  named_scope :non_rewarded, :conditions => "NOT rewarded"
  named_scope :rewarded, :conditions => "rewarded"
  named_scope :featured, :conditions => { :featured => true }
  named_scope :apps, :conditions => { :item_type => 'App' }
  named_scope :free, :conditions => { :price => 0 }
  named_scope :nonfeatured, :conditions => { :featured => false }
  named_scope :visible, :conditions => { :hidden => false }
  named_scope :to_aggregate_hourly_stats, lambda { { :conditions => [ "next_stats_aggregation_time < ?", Time.zone.now ], :select => :id } }
  named_scope :to_aggregate_daily_stats, lambda { { :conditions => [ "next_daily_stats_aggregation_time < ?", Time.zone.now ], :select => :id } }
  named_scope :updated_before, lambda { |time| { :conditions => [ "#{quoted_table_name}.updated_at < ?", time ] } }
  named_scope :app_offers, :conditions => "item_type = 'App' or item_type = 'ActionOffer'"
  named_scope :video_offers, :conditions => "item_type = 'VideoOffer'"
  named_scope :non_video_offers, :conditions => "item_type != 'VideoOffer'"
  named_scope :papaya_app_offers, :joins => :app, :conditions => "item_type = 'App' AND #{App.quoted_table_name}.papaya_user_count > 0", :select => PAPAYA_OFFER_COLUMNS
  named_scope :papaya_action_offers, :joins => { :action_offer => :app }, :conditions => "item_type = 'ActionOffer' AND #{App.quoted_table_name}.papaya_user_count > 0", :select => PAPAYA_OFFER_COLUMNS
  named_scope :tapjoy_sponsored_offer_ids, :conditions => "tapjoy_sponsored = true", :select => "#{Offer.quoted_table_name}.id"
  named_scope :creative_approval_needed, :conditions => ['banner_creatives != approved_banner_creatives OR (banner_creatives IS NOT NULL AND banner_creatives != ? AND approved_banner_creatives IS NULL)', "--- []\n\n"]

  delegate :balance, :pending_earnings, :name, :cs_contact_email, :approved_publisher?, :rev_share, :to => :partner, :prefix => true
  memoize :partner_balance

  alias_method :events, :offer_events
  alias_method :random, :rand

  json_set_field :device_types, :screen_layout_sizes, :countries, :dma_codes, :regions, :approved_sources
  memoize :get_device_types, :get_screen_layout_sizes, :get_countries, :get_dma_codes, :get_regions, :get_approved_sources

  # Our relationship wasn't working, and this allows the ActionOffer.app crap to work
  def app
    return item if item_type == 'App'
    return item.app if ['ActionOffer', 'RatingOffer'].include?(item_type)
  end

  def clone
    clone = super

    # set up banner_creatives to be copied on save
    banner_creatives.each do |size|
      blob = banner_creative_s3_object(size).read
      clone.send("banner_creative_#{size}_blob=", blob)
    end
    clone
  end

  def app_offer?
    item_type == 'App' || item_type == 'ActionOffer'
  end

  def get_countries_blacklist
    if app_offer?
      item.get_countries_blacklist
    else
      []
    end
  end
  memoize :get_countries_blacklist

  def banner_creatives
    self.banner_creatives = [] if super.nil?
    super.sort
  end

  def approved_banner_creatives
    self.approved_banner_creatives = [] if super.nil?
    super.sort
  end

  def banner_creatives_was
    ret_val = super
    return [] if ret_val.nil?
    ret_val
  end

  def should_update_approved_banner_creatives?
    banner_creatives_changed? && banner_creatives != approved_banner_creatives
  end

  def banner_creatives_changed?
    return false if (super && banner_creatives_was.empty? && banner_creatives.empty?)
    super
  end

  def has_banner_creative?(size)
    self.banner_creatives.include?(size)
  end

  def banner_creative_approved?(size)
    has_banner_creative?(size) && self.approved_banner_creatives.include?(size)
  end

  def remove_banner_creative(size)
    return unless has_banner_creative?(size)
    self.banner_creatives = banner_creatives.reject { |c| c == size }
    self.approved_banner_creatives = approved_banner_creatives.reject { |c| c == size }
  end

  def add_banner_creative(size)
    return if has_banner_creative?(size)
    self.banner_creatives += [size]
  end

  def approve_banner_creative(size)
    return unless has_banner_creative?(size)
    return if banner_creative_approved?(size)
    self.approved_banner_creatives += [size]
  end

  def add_banner_approval(user, size)
    approvals << CreativeApprovalQueue.new(:offer => self, :user => user, :size => size)
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

  def send_low_conversion_email?
    item_id == id || !primary_offer_enabled?
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

  def banner_creative_format(size)
    return 'jpeg' if FEATURED_AD_SIZES.include? size
    'png'
  end

  def banner_creative_path(size, format = nil)
    format ||= banner_creative_format(size)
    "banner_creatives/#{Offer.hashed_icon_id(id)}_#{size}.#{format}"
  end

  def banner_creative_s3_object(size, format = nil)
    format ||= banner_creative_format(size)
    bucket = S3.bucket(BucketNames::TAPJOY)
    bucket.objects[banner_creative_path(size, format)]
  end

  def banner_creative_mc_key(size, format = nil)
    format ||= banner_creative_format(size)
    banner_creative_path(size, format).gsub('/', '.')
  end

  def display_custom_banner_for_size?(size)
    display_banner_ads? && banner_creative_approved?(size)
  end

  def get_video_icon_url(options = {})
    if item_type == 'VideoOffer' || item_type == 'TestVideoOffer'
      object = S3.bucket(BucketNames::TAPJOY).objects["icons/src/#{Offer.hashed_icon_id(icon_id)}.jpg"]
      begin
        object.exists? ? get_icon_url({:source => :cloudfront}.merge(options)) : "#{CLOUDFRONT_URL}/videos/assets/default.png"
      rescue AWS::Errors::Base
        "#{CLOUDFRONT_URL}/videos/assets/default.png"
      end
    end
  end
  memoize :get_video_icon_url

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

    if item_type == 'VideoOffer'
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
  end

  def get_video_url(options = {})
    Offer.get_video_url({:video_id => Offer.id}.merge(options))
  end

  def self.get_video_url(options = {})
    video_id  = options.delete(:video_id)  { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy"

    "#{prefix}/videos/src/#{video_id}.mp4"
  end

  def save(perform_validation = true)
    super(perform_validation)
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
      App::PLATFORMS.index(get_platform) != item.platform
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
    if (force_update || bid_changed? || new_record?)
      if (item_type == 'App' || item_type == 'ActionOffer')
        self.payment = bid * (100 - partner.premier_discount) / 100
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

  def unlimited_budget?
    daily_budget.zero? && overall_budget.zero?
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

  def display_banner_ads?
    return false if (is_paid? || featured?)
    return (item_type == 'App' && name.length <= 30) if rewarded?
    item_type != 'VideoOffer'
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

  def cached_support_requests_rewards
    support_requests = Mc.get("offer.support_requests.#{id}")
    rewards = Mc.get("offer.clicks_rewarded.#{id}")
    [ support_requests, rewards ]
  end

  def multi_completable?
    item_type != 'App' || Offer::Rejecting::TAPJOY_GAMES_RETARGETED_OFFERS.include?(item_id)
  end

  private

  def calculated_min_bid
    if item_type == 'App'
      if featured? && rewarded?
        is_paid? ? price : (get_platform == 'iOS' ? 65 : 10)
      elsif !rewarded?
        100
      else
        is_paid? ? (price * 0.50).round : 10
      end
    elsif item_type == 'ActionOffer'
      if is_paid?
        (price * 0.50).round
      else
        platform = App::PLATFORMS.index(get_platform)
        platform.nil? ? 35 : App::PLATFORM_DETAILS[platform][:min_action_offer_bid]
      end
    elsif item_type == 'VideoOffer'
      15
    else
      0
    end
  end

  def custom_creative_sizes(return_all = false)
    return Offer::DISPLAY_AD_SIZES + Offer::FEATURED_AD_SIZES if return_all

    if !rewarded? && !featured?
      Offer::DISPLAY_AD_SIZES
    elsif featured?
      Offer::FEATURED_AD_SIZES
    else
      []
    end
  end

  def sync_creative_approval
    # Handle banners on this end
    banner_creatives.each do |size|
      approval = approvals.find_by_size(size)

      if banner_creative_approved?(size)
        approval.try(:destroy)
      elsif approval.nil?
        # In case of a desync between the queue and actual approvals
        approve_banner_creative(size)
      end
    end

    # Now remove any approval objects that are no longer valid
    approvals.each do |approval|
      approval.destroy unless has_banner_creative?(approval.size)
    end

    # Remove out-of-sync approvals for banners that have been removed
    self.approved_banner_creatives = self.approved_banner_creatives.select do |size|
      has_banner_creative?(size)
    end
  end

  def sync_banner_creatives!
    # How this should work...
    #
    # ONE OF:
    #
    # adding new creative(s):
    # offer.banner_creatives += ["320x50", "640x100"]
    # offer.banner_creative_320x50_blob = image_data
    # offer.banner_creative_640x100_blob = image_data
    # offer.save!
    #
    # removing creative: (only one at a time allowed)
    # offer.banner_creatives -= ["320x50"]
    # offer.save!
    #
    # updating creative: (only one at a time allowed)
    # offer.banner_creative_320x50_blob = image_data
    # offer.save!
    #
    creative_blobs = {}

    custom_creative_sizes(true).each do |size|
      image_data = (send("banner_creative_#{size}_blob") rescue nil)
      creative_blobs[size] = image_data if !image_data.blank?
    end

    return if (!banner_creatives_changed? && creative_blobs.empty?)

    new_creatives = banner_creatives - banner_creatives_was
    removed_creatives = banner_creatives_was - banner_creatives
    changed_creatives = creative_blobs.keys - new_creatives

    if new_creatives.any?
      raise "Unable to delete or update creatives while also adding creatives" if (removed_creatives.any? || changed_creatives.any?)
    elsif (banner_creatives.size - banner_creatives_was.size).abs > 1 || creative_blobs.size > 1
      raise "Unable to delete or update more than one banner creative at a time"
    end

    error_added = false
    new_creatives.each do |new_size|
      unless creative_blobs.has_key?(new_size)
        self.errors.add("custom_creative_#{new_size}_blob".to_sym, "#{new_size} custom creative file not provided.")
        error_added = true
        next
      end
      blob = creative_blobs[new_size]
      # upload to S3
      upload_banner_creative!(blob, new_size)
    end
    raise BannerSyncError.new("multiple new file upload errors") if error_added

    removed_creatives.each do |removed_size|
      # delete from S3
      delete_banner_creative!(removed_size)
    end

    changed_creatives.each do |changed_size|
      blob = creative_blobs[changed_size]
      # upload file to S3
      upload_banner_creative!(blob, changed_size)
    end
  end

  def clear_creative_blobs
    CUSTOM_AD_SIZES.each do |size|
      blob = send("banner_creative_#{size}_blob")
      blob.replace("") if blob
    end
  end

  def delete_banner_creative!(size, format = nil)
    format ||= banner_creative_format(size)
    banner_creative_s3_object(size, format).delete
  rescue
    raise BannerSyncError.new("Encountered unexpected error while deleting existing file, please try again.", "custom_creative_#{size}_blob")
  end

  def upload_banner_creative!(blob, size, format = nil)
    format ||= banner_creative_format(size)
    begin
      creative_arr = Magick::Image.from_blob(blob)
      if creative_arr.size != 1
        raise "image contains multiple layers (e.g. animated .gif)"
      end
      creative = creative_arr[0]
      creative.format = format
      creative.interlace = Magick::JPEGInterlace if format == 'jpeg'
    rescue
      raise BannerSyncError.new("New file is invalid - unable to convert to .#{format}.", "custom_creative_#{size}_blob")
    end

    width, height = size.split("x").collect{|x|x.to_i}
    raise BannerSyncError.new("New file has invalid dimensions.", "custom_creative_#{size}_blob") if [width, height] != [creative.columns, creative.rows]

    begin
      banner_creative_s3_object(size, format).write(:data => creative.to_blob { self.quality = 85 }, :acl => :public_read)
    rescue
      raise BannerSyncError.new("Encountered unexpected error while uploading new file, please try again.", "custom_creative_#{size}_blob")
    end

    # Add to memcache
    begin
      Mc.put(banner_creative_mc_key(size, format), Base64.encode64(creative.to_blob).gsub("\n", ''))
    rescue
      # no worries, it will get cached later if needed
    end

    CloudFront.invalidate(id, banner_creative_path(size, format))
  end

  def is_test_device?(currency, device)
    currency.get_test_device_ids.include?(device.id)
  end

  def is_test_video_offer?(type)
    type == 'TestVideoOffer'
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
end

class BannerSyncError < StandardError;
  attr_accessor :offer_attr_name
  def initialize(message, offer_attr_name = nil)
    super(message)
    self.offer_attr_name = offer_attr_name
  end
end
