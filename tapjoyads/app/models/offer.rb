class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  include Offer::Ranking
  include Offer::Rejecting
  include Offer::UrlGeneration
  acts_as_cacheable

  APPLE_DEVICES = %w( iphone itouch ipad )
  IPAD_DEVICES = %w( ipad )
  ANDROID_DEVICES = %w( android )
  WINDOWS_DEVICES = %w( windows )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES + WINDOWS_DEVICES
  EXEMPT_UDIDS = Set.new(['7bed2150f941bad724c42413c5efa7f202c502e0',
                          'a000002256c234'])

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
    FEATURED_OFFER_TYPE              => 'Featured Offers',
    DISPLAY_OFFER_TYPE               => 'Display Ad Offers',
    NON_REWARDED_DISPLAY_OFFER_TYPE  => 'Non-Rewarded Display Ad Offers',
    NON_REWARDED_FEATURED_OFFER_TYPE => 'Non-Rewarded Featured Offers',
    VIDEO_OFFER_TYPE                 => 'Video Offers',
    FEATURED_BACKFILLED_OFFER_TYPE   => 'Featured Offers (Backfilled)',
    NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE => 'Non-Rewarded Featured Offers (Backfilled)'
  }

  DISPLAY_AD_SIZES = ['320x50', '640x100', '768x90']
  
  OFFER_LIST_REQUIRED_COLUMNS = [ 'id', 'item_id', 'item_type', 'partner_id',
                                  'name', 'url', 'price', 'bid', 'payment',
                                  'conversion_rate', 'show_rate', 'self_promote_only',
                                  'device_types', 'countries', 'postal_codes', 'cities',
                                  'age_rating', 'multi_complete', 'featured',
                                  'publisher_app_whitelist', 'direct_pay', 'reward_value',
                                  'third_party_data', 'payment_range_low',
                                  'payment_range_high', 'icon_id_override', 'rank_boost',
                                  'normal_bid', 'normal_conversion_rate', 'normal_avg_revenue',
                                  'normal_price', 'over_threshold', 'rewarded', 'reseller_id',
                                  'cookie_tracking', 'min_os_version', 'screen_layout_sizes', 'interval' ].map { |c| "#{quoted_table_name}.#{c}" }.join(', ')

  DIRECT_PAY_PROVIDERS = %w( boku paypal )

  DAILY_STATS_START_HOUR = 6
  DAILY_STATS_RANGE = 6
  
  FREQUENCIES_CAPPING_INTERVAL = {
    "none"     => 0,
    "1 minute" => 1.minute.to_i,
    "1 hour"   => 1.hour.to_i,
    "8 hours"  => 8.hours.to_i,
    "24 hours" => 24.hours.to_i,
  }

  serialize :banner_creatives, Array
  
  DISPLAY_AD_SIZES.each do |size|
    attr_accessor "banner_creative_#{size}_blob".to_sym
  end

  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  has_many :rank_boosts
  has_many :enable_offer_requests
  has_many :dependent_action_offers, :class_name => 'ActionOffer', :foreign_key => :prerequisite_offer_id
  has_many :offer_events
  has_many :editors_picks

  belongs_to :partner
  belongs_to :item, :polymorphic => true
  belongs_to :reseller

  validates_presence_of :reseller, :if => Proc.new { |offer| offer.reseller_id? }
  validates_presence_of :partner, :item, :name, :url, :rank_boost
  validates_numericality_of :price, :interval, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => false
  validates_numericality_of :bid, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10000, :allow_nil => false
  validates_numericality_of :min_bid_override, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :rank_boost, :allow_nil => false, :only_integer => true
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :self_promote_only, :featured, :multi_complete, :rewarded, :cookie_tracking, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer GenericOffer OfferpalOffer RatingOffer ActionOffer VideoOffer)
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
      record.errors.add(attribute, "is not for App offers") if record.item_type == 'App'
      record.errors.add(attribute, "cannot be used for pay-per-click offers") if record.pay_per_click?
    end
  end
  validate :bid_higher_than_min_bid

  before_validation :update_payment
  before_validation_on_create :set_reseller_from_partner
  before_create :set_stats_aggregation_times
  before_save :cleanup_url
  before_save :fix_country_targeting
  before_save :update_payment
  after_save :update_enabled_rating_offer_id
  after_save :update_pending_enable_requests
  after_save :sync_banner_creatives! # NOTE: this should always be the last thing run by the after_save callback chain

  named_scope :enabled_offers, :joins => :partner,
    :readonly => false, :conditions => "tapjoy_enabled = true AND user_enabled = true AND item_type != 'RatingOffer' AND ((payment > 0 AND #{Partner.quoted_table_name}.balance > payment) OR (payment = 0 AND reward_value > 0))"
  named_scope :by_name, lambda { |offer_name| { :conditions => ["offers.name LIKE ?", "%#{offer_name}%" ] } }
  named_scope :by_device, lambda { |platform| { :conditions => ["offers.device_types LIKE ?", "%#{platform}%" ] } }
  named_scope :for_offer_list, :select => OFFER_LIST_REQUIRED_COLUMNS
  named_scope :for_display_ads, :conditions => "item_type = 'App' AND price = 0 AND conversion_rate >= 0.3 AND LENGTH(offers.name) <= 30"
  named_scope :non_rewarded, :conditions => "NOT rewarded"
  named_scope :rewarded, :conditions => "rewarded"
  named_scope :featured, :conditions => { :featured => true }
  named_scope :free_apps, :conditions => { :item_type => 'App', :price => 0 }
  named_scope :nonfeatured, :conditions => { :featured => false }
  named_scope :visible, :conditions => { :hidden => false }
  named_scope :to_aggregate_hourly_stats, lambda { { :conditions => [ "next_stats_aggregation_time < ?", Time.zone.now ], :select => :id } }
  named_scope :to_aggregate_daily_stats, lambda { { :conditions => [ "next_daily_stats_aggregation_time < ?", Time.zone.now ], :select => :id } }
  named_scope :updated_before, lambda { |time| { :conditions => [ "#{quoted_table_name}.updated_at < ?", time ] } }
  named_scope :app_offers, :conditions => "item_type = 'App' or item_type = 'ActionOffer'"
  named_scope :video_offers, :conditions => "item_type = 'VideoOffer'"
  named_scope :non_video_offers, :conditions => "item_type != 'VideoOffer'"

  delegate :balance, :pending_earnings, :name, :approved_publisher?, :rev_share, :to => :partner, :prefix => true
  memoize :partner_balance
  
  alias_method :events, :offer_events
  alias_method :random, :rand

  json_set_field :device_types, :screen_layout_sizes, :countries, :cities, :postal_codes
  memoize :get_device_types, :get_screen_layout_sizes, :get_countries, :get_cities, :get_postal_codes

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
    super
  end
  
  def banner_creatives_was
    return [] if super.nil?
    super
  end
  
  def banner_creatives_changed?
    return false if (super && banner_creatives_was.empty? && banner_creatives.empty?)
    super
  end

  def self.redistribute_hourly_stats_aggregation
    Benchmark.realtime do
      now = Time.zone.now + 15.minutes
      Offer.find_each do |o|
        o.next_stats_aggregation_time = now + rand(1.hour)
        o.save(false)
      end
    end
  end

  def self.redistribute_daily_stats_aggregation
    Benchmark.realtime do
      now = Time.zone.now + 15.minutes
      Offer.find_each do |o|
        if now.hour >= DAILY_STATS_START_HOUR && now.hour < (DAILY_STATS_START_HOUR + DAILY_STATS_RANGE)
          o.next_daily_stats_aggregation_time = now + rand(DAILY_STATS_RANGE.hours)
        else
          o.next_daily_stats_aggregation_time = (now - DAILY_STATS_START_HOUR.hours + 1.day).beginning_of_day + DAILY_STATS_START_HOUR.hours + rand(DAILY_STATS_RANGE.hours)
        end
        o.save(false)
      end
    end
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
  
  def banner_creative_path(size, format='png')
    "banner_creatives/#{Offer.hashed_icon_id(id)}_#{size}.#{format}"
  end
  
  def banner_creative_s3_key(size, format='png')
    bucket = AWS::S3.new.buckets[BucketNames::TAPJOY]
    bucket.objects[banner_creative_path(size, format)]
  end
  
  def banner_creative_mc_key(size, format='png')
    banner_creative_path(size, format).gsub('/','.')
  end
  
  def display_custom_banner_for_size?(size)
    return !rewarded? && !featured? && is_free? && item_type != 'VideoOffer' && banner_creatives.include?(size)
  end
  
  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(icon_id), :item_type => item_type}.merge(options))
  end

  def self.get_icon_url(options = {})
    source     = options.delete(:source)   { :s3 }
    size       = options.delete(:size)     { '57' }
    icon_id    = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
    item_type  = options.delete(:item_type)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL
    
    if item_type == 'VideoOffer' || item_type == 'TestVideoOffer'
      bucket = S3.bucket(BucketNames::TAPJOY)
      existing_icon_blob = bucket.get("icons/src/#{icon_id}.jpg") rescue ''
      size = '200'
      return "#{prefix}/videos/assets/default.png" if existing_icon_blob.blank?
    end
    
    "#{prefix}/icons/#{size}/#{icon_id}.jpg"
  end

  def save_icon!(icon_src_blob)
    bucket = S3.bucket(BucketNames::TAPJOY)

    icon_id = Offer.hashed_icon_id(id)
    existing_icon_blob = bucket.get("icons/src/#{icon_id}.jpg") rescue ''

    return if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)
    
    if item_type == 'VideoOffer'
      icon_200 = Magick::Image.from_blob(icon_src_blob)[0].resize(200, 125).opaque('#ffffff00', 'white')
      corner_mask_blob = bucket.get("display/round_mask_200x125.png")
      corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(200, 125)
      icon_200.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
      icon_200 = icon_200.opaque('#ffffff00', 'white')
      icon_200.alpha(Magick::OpaqueAlphaChannel)
      
      icon_200_blob = icon_200.to_blob{|i| i.format = 'JPG'}
      
      bucket.put("icons/src/#{icon_id}.jpg", icon_src_blob, {}, "public-read")
      bucket.put("icons/200/#{icon_id}.jpg", icon_200_blob, {}, "public-read")
      
      Mc.delete("icon.s3.#{id}")
      return
    end
    
    icon_256 = Magick::Image.from_blob(icon_src_blob)[0].resize(256, 256).opaque('#ffffff00', 'white')
    
    corner_mask_blob = bucket.get("display/round_mask.png")
    corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(256, 256)
    icon_256.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
    icon_256 = icon_256.opaque('#ffffff00', 'white')
    icon_256.alpha(Magick::OpaqueAlphaChannel)

    icon_256_blob = icon_256.to_blob{|i| i.format = 'JPG'}
    icon_114_blob = icon_256.resize(114, 114).to_blob{|i| i.format = 'JPG'}
    icon_57_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'JPG'}
    icon_57_png_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'PNG'}

    bucket.put("icons/src/#{icon_id}.jpg", icon_src_blob, {}, "public-read")
    bucket.put("icons/256/#{icon_id}.jpg", icon_256_blob, {}, "public-read")
    bucket.put("icons/114/#{icon_id}.jpg", icon_114_blob, {}, "public-read")
    bucket.put("icons/57/#{icon_id}.jpg", icon_57_blob, {}, "public-read")
    bucket.put("icons/57/#{icon_id}.png", icon_57_png_blob, {}, "public-read")
    
    Mc.delete("icon.s3.#{id}")

    # Invalidate cloudfront
    if existing_icon_blob.present?
      begin
        acf = RightAws::AcfInterface.new
        acf.invalidate('E1MG6JDV6GH0F2', ["/icons/256/#{icon_id}.jpg", "/icons/114/#{icon_id}.jpg", "/icons/57/#{icon_id}.jpg", "/icons/57/#{icon_id}.png"], "#{id}.#{Time.now.to_i}")
      rescue Exception => e
        Notifier.alert_new_relic(FailedToInvalidateCloudfront, e.message)
      end
    end
  end

  def get_video_url(options = {})
    Offer.get_video_url({:video_id => Offer.id}.merge(options))
  end
  
  def self.get_video_url(options = {})
    video_id  = options.delete(:video_id)  { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    prefix = "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy"
    
    "#{prefix}/videos/src/#{video_id}.mp4"
  end
  
  def save(perform_validation = true)
    super(perform_validation)
  rescue BannerSyncError => bse
    self.errors.add(bse.offer_attr_name.to_sym, bse.message)
    false
  end
  
  def save_video!(video_src_blob)
    bucket = S3.bucket(BucketNames::TAPJOY)
    
    key = bucket.key("videos/src/#{id}.mp4")
    existing_video_blob = key.exists? ? key.get : ''
    
    return if Digest::MD5.hexdigest(video_src_blob) == Digest::MD5.hexdigest(existing_video_blob)
    
    bucket.put("videos/src/#{id}.mp4", video_src_blob, {}, "public-read")
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
    return min_bid_override if min_bid_override

    if item_type == 'App'
      if featured? && rewarded?
        is_paid? ? price : 65
      elsif !rewarded?
        50
      else
        is_paid? ? (price * 0.50).round : 35
        # uncomment for tapjoy premier & change show.html line 92-ish
        # is_paid? ? (price * 0.65).round : 50
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

  def create_featured_clone
    featured_offer = self.clone
    featured_offer.featured = true
    featured_offer.name_suffix = "featured"
    featured_offer.bid = featured_offer.min_bid
    featured_offer.tapjoy_enabled = false
    featured_offer.save!
    featured_offer
  end

  def create_non_rewarded_clone
    non_rewarded_offer = self.clone
    non_rewarded_offer.rewarded = false
    non_rewarded_offer.name_suffix = "non-rewarded"
    non_rewarded_offer.bid = non_rewarded_offer.min_bid
    non_rewarded_offer.tapjoy_enabled = false
    non_rewarded_offer.save!
    non_rewarded_offer
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

private
  
  def sync_banner_creatives!
    creative_blobs = {}
    Offer::DISPLAY_AD_SIZES.each do |size|
      image_data = (send("banner_creative_#{size}_blob") rescue nil)
      creative_blobs[size] = image_data if !image_data.blank?
    end
    
    return if (!banner_creatives_changed? && creative_blobs.empty?)
    if (banner_creatives.size - banner_creatives_was.size).abs > 1 || creative_blobs.size > 1
      raise "Unable to sync changes to more than one banner creative at a time"
    end
    
    blob = creative_blobs.values.first # will be nil for banner creative removals
    if banner_creatives.size > banner_creatives_was.size
      # banner creative added, find which size was added and make sure file matches up
      new_size = (banner_creatives - banner_creatives_was).first
      raise BannerSyncError.new("custom_creative_#{new_size}_blob", "#{new_size} banner creative file not provided.") if creative_blobs[new_size].nil?
      
      # upload to S3
      upload_banner_creative!(blob, new_size)
    elsif banner_creatives_was.size > banner_creatives.size
      # banner creative removed, find which size was removed
      removed_size = (banner_creatives_was - banner_creatives).first
      
      # delete from S3
      delete_banner_creative!(removed_size)
    else
      # a banner creative was changed, find which size it applies to
      size = creative_blobs.keys.first
      
      # upload file to S3
      upload_banner_creative!(blob, size)
    end
    
    # 'acts_as_cacheable' caches entire object, including all attributes, so... let's clear the blob
    blob.replace("") if blob
  end
  
  def delete_banner_creative!(size, format='png')
    banner_creative_s3_key(size, format).delete
  rescue
    raise BannerSyncError.new("custom_creative_#{size}_blob", "Encountered unexpected error while deleting existing file, please try again.")
  end
  
  def upload_banner_creative!(blob, size, format='png')
    begin
      creative_arr = Magick::Image.from_blob(blob)
      if creative_arr.size != 1
        raise "image contains multiple layers (e.g. animated .gif)"
      end
      creative = creative_arr[0]
      creative.format = format
    rescue
      raise BannerSyncError.new("custom_creative_#{size}_blob", "New file is invalid - unable to convert to .#{format}.")
    end
    
    width, height = size.split("x").collect{|x|x.to_i}
    raise BannerSyncError.new("custom_creative_#{size}_blob", "New file has invalid dimensions.") if [width, height] != [creative.columns, creative.rows]
    
    begin
      banner_creative_s3_key(size, format).write(:data => creative.to_blob, :acl => :public_read)
    rescue
      raise BannerSyncError.new("custom_creative_#{size}_blob", "Encountered unexpected error while uploading new file, please try again.")
    end
    
    # Add to memcache
    begin
      Mc.put(banner_creative_mc_key(size, format), Base64.encode64(creative.to_blob).gsub("\n", ''))
    rescue
      # no worries, it will get cached later if needed
    end

    # Invalidate cloudfront
    begin
      acf = RightAws::AcfInterface.new
      acf.invalidate('E1MG6JDV6GH0F2', banner_creative_path(size, format).to_a, "#{id}.#{Time.now.to_i}")
    rescue Exception => e
      Notifier.alert_new_relic(FailedToInvalidateCloudfront, e.message)
    end
  end
  
  def is_test_device?(currency, device)
    currency.get_test_device_ids.include?(device.id)
  end
  
  def is_test_video_offer?(type)
    type == 'TestVideoOffer'
  end
  
  def cleanup_url
    if (url_overridden_changed? || url_changed?) && !url_overridden? && %w(App ActionOffer RatingOffer).include?(item_type)
      self.url = self.item.store_url
    end
    self.url = url.gsub(" ", "%20")
  end

  def set_stats_aggregation_times
    now = Time.now.utc
    self.next_stats_aggregation_time = now if next_stats_aggregation_time.blank?
    self.next_daily_stats_aggregation_time = (now + 1.day).beginning_of_day + DAILY_STATS_START_HOUR.hours + rand(DAILY_STATS_RANGE.hours) if next_daily_stats_aggregation_time.blank?
  end

  def bid_higher_than_min_bid
    if bid_changed? || price_changed?
      if bid < min_bid
        errors.add :bid, "is below the minimum (#{min_bid} cents)"
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

  def fix_country_targeting
    unless countries.blank?
      countries.gsub!(/uk/i, 'GB')
    end
  end

end

class BannerSyncError < StandardError;
  attr_accessor :offer_attr_name
  def initialize(offer_attr_name, message)
    super(message)
    self.offer_attr_name = offer_attr_name
  end
end
