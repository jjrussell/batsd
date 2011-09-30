class Offer < ActiveRecord::Base
  include UuidPrimaryKey
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
  OFFER_TYPE_NAMES = {
    DEFAULT_OFFER_TYPE               => 'Offerwall Offers',
    FEATURED_OFFER_TYPE              => 'Featured Offers',
    DISPLAY_OFFER_TYPE               => 'Display Ad Offers',
    NON_REWARDED_DISPLAY_OFFER_TYPE  => 'Non-Rewarded Display Ad Offers',
    NON_REWARDED_FEATURED_OFFER_TYPE => 'Non-Rewarded Featured Offers',
    VIDEO_OFFER_TYPE                 => 'Video Offers'
  }

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

  attr_accessor :rank_score

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
  before_save :calculate_ranking_fields
  after_save :update_enabled_rating_offer_id
  after_save :update_pending_enable_requests

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

  def avg_revenue
    conversion_rate * bid_for_ranks
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

  def destination_url(options)
    if instructions.present?
      instructions_url(options)
    else
      complete_action_url(options)
    end
  end

  def instructions_url(options)
    udid                  = options.delete(:udid)                  { |k| raise "#{k} is a required argument" }
    publisher_app_id      = options.delete(:publisher_app_id)      { |k| raise "#{k} is a required argument" }
    currency              = options.delete(:currency)              { |k| raise "#{k} is a required argument" }
    click_key             = options.delete(:click_key)             { nil }
    language_code         = options.delete(:language_code)         { nil }
    itunes_link_affiliate = options.delete(:itunes_link_affiliate) { nil }
    display_multiplier    = options.delete(:display_multiplier)    { 1 }
    library_version       = options.delete(:library_version)       { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    data = {
      :id                    => id,
      :udid                  => udid,
      :publisher_app_id      => publisher_app_id,
      :click_key             => click_key,
      :itunes_link_affiliate => itunes_link_affiliate,
      :currency_id           => currency.id,
      :language_code         => language_code,
      :display_multiplier    => display_multiplier,
      :library_version       => library_version,
    }

    "#{API_URL}/offer_instructions?data=#{SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)}"
  end

  def complete_action_url(options)
    udid                  = options.delete(:udid)                  { |k| raise "#{k} is a required argument" }
    publisher_app_id      = options.delete(:publisher_app_id)      { |k| raise "#{k} is a required argument" }
    currency              = options.delete(:currency)              { |k| raise "#{k} is a required argument" }
    click_key             = options.delete(:click_key)             { nil }
    itunes_link_affiliate = options.delete(:itunes_link_affiliate) { nil }
    library_version       = options.delete(:library_version)       { nil }
    options.delete(:language_code)
    options.delete(:display_multiplier)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    final_url = url.gsub('TAPJOY_UDID', udid.to_s)
    if item_type == 'App'
      if final_url =~ /^http:\/\/phobos\.apple\.com/
        final_url += '&referrer=tapjoy'

        if itunes_link_affiliate == 'tradedoubler'
          final_url += '&partnerId=2003&tduid=UK1800811'
        else
          final_url += '&partnerId=30&siteID=OxXMC6MRBt4'
        end
      elsif library_version.nil? || library_version.version_greater_than_or_equal_to?('8.1.1')
        final_url.sub!('market://search?q=', 'http://market.android.com/details?id=')
      end
    elsif item_type == 'EmailOffer'
      final_url += "&publisher_app_id=#{publisher_app_id}"
    elsif item_type == 'GenericOffer'
      final_url.gsub!('TAPJOY_GENERIC', click_key.to_s)
      if has_variable_payment?
        extra_params = {
          :uid      => Digest::SHA256.hexdigest(udid + UDID_SALT),
          :cvr      => currency.spend_share * currency.conversion_rate / 100,
          :currency => CGI::escape(currency.name),
        }
        mark = '?'
        mark = '&' if final_url =~ /\?/
        final_url += "#{mark}#{extra_params.to_query}"
      end
    elsif item_type == 'ActionOffer'
      final_url = url
    end

    final_url
  end

  def get_click_url(options)
    publisher_app      = options.delete(:publisher_app)      { |k| raise "#{k} is a required argument" }
    publisher_user_id  = options.delete(:publisher_user_id)  { |k| raise "#{k} is a required argument" }
    udid               = options.delete(:udid)               { |k| raise "#{k} is a required argument" }
    currency_id        = options.delete(:currency_id)        { |k| raise "#{k} is a required argument" }
    source             = options.delete(:source)             { |k| raise "#{k} is a required argument" }
    app_version        = options.delete(:app_version)        { nil }
    viewed_at          = options.delete(:viewed_at)          { |k| raise "#{k} is a required argument" }
    displayer_app_id   = options.delete(:displayer_app_id)   { nil }
    exp                = options.delete(:exp)                { nil }
    country_code       = options.delete(:country_code)       { nil }
    language_code      = options.delete(:language_code)      { nil }
    display_multiplier = options.delete(:display_multiplier) { 1 }
    device_name        = options.delete(:device_name)        { nil }
    library_version    = options.delete(:library_version)    { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    click_url = "#{API_URL}/click/"
    if item_type == 'App' || item_type == 'EmailOffer'
      click_url += "app"
    elsif item_type == 'GenericOffer'
      click_url += "generic"
    elsif item_type == 'RatingOffer'
      click_url += "rating"
    elsif item_type == 'TestOffer'
      click_url += "test_offer"
    elsif item_type == 'TestVideoOffer'
      click_url += "test_video_offer"
    elsif item_type == 'ActionOffer'
      click_url += "action"
    elsif item_type == 'VideoOffer'
      click_url += "video"
    else
      raise "click_url requested for an offer that should not be enabled. offer_id: #{id}"
    end

    data = {
      :advertiser_app_id  => item_id,
      :publisher_app_id   => publisher_app.id,
      :publisher_user_id  => publisher_user_id,
      :udid               => udid,
      :source             => source,
      :offer_id           => id,
      :app_version        => app_version,
      :viewed_at          => viewed_at.to_f,
      :currency_id        => currency_id,
      :country_code       => country_code,
      :displayer_app_id   => displayer_app_id,
      :exp                => exp,
      :language_code      => language_code,
      :display_multiplier => display_multiplier,
      :device_name        => device_name,
      :library_version    => library_version,
    }

    "#{click_url}?data=#{SymmetricCrypto.encrypt_object(data, SYMMETRIC_CRYPTO_SECRET)}"
  end

  def get_fullscreen_ad_url(options)
    publisher_app      = options.delete(:publisher_app)      { |k| raise "#{k} is a required argument" }
    publisher_user_id  = options.delete(:publisher_user_id)  { |k| raise "#{k} is a required argument" }
    udid               = options.delete(:udid)               { |k| raise "#{k} is a required argument" }
    currency_id        = options.delete(:currency_id)        { |k| raise "#{k} is a required argument" }
    source             = options.delete(:source)             { |k| raise "#{k} is a required argument" }
    app_version        = options.delete(:app_version)        { nil }
    viewed_at          = options.delete(:viewed_at)          { |k| raise "#{k} is a required argument" }
    displayer_app_id   = options.delete(:displayer_app_id)   { nil }
    exp                = options.delete(:exp)                { nil }
    country_code       = options.delete(:country_code)       { nil }
    display_multiplier = options.delete(:display_multiplier) { 1 }
    library_version    = options.delete(:library_version)    { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    ad_url = "#{API_URL}/fullscreen_ad"
    if item_type == 'TestOffer'
      ad_url += "/test_offer"
    elsif item_type == 'TestVideoOffer'
      ad_url += "/test_video_offer"
    end
    ad_url += "?advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app.id}&publisher_user_id=#{publisher_user_id}&udid=#{udid}&source=#{source}&offer_id=#{id}&app_version=#{app_version}&viewed_at=#{viewed_at.to_f}&currency_id=#{currency_id}&country_code=#{country_code}&display_multiplier=#{display_multiplier}&library_version=#{library_version}"
    ad_url += "&displayer_app_id=#{displayer_app_id}" if displayer_app_id.present?
    ad_url += "&exp=#{exp}" if exp.present?
    ad_url
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

  def calculate_ranking_fields
    return if Rails.env == 'test' # We need to be seeding the test environment with enabled offers for these calculations to work
    stats                       = OfferCacher.get_offer_stats
    self.normal_conversion_rate = (stats[:cvr_std_dev] == 0) ? 0 : (conversion_rate - stats[:cvr_mean]) / stats[:cvr_std_dev]
    self.normal_price           = (stats[:price_std_dev] == 0) ? 0 : (price - stats[:price_mean]) / stats[:price_std_dev]
    self.normal_avg_revenue     = (stats[:avg_revenue_std_dev] == 0) ? 0 : (avg_revenue - stats[:avg_revenue_mean]) / stats[:avg_revenue_std_dev]
    self.normal_bid             = (stats[:bid_std_dev] == 0) ? 0 : (bid_for_ranks - stats[:bid_mean]) / stats[:bid_std_dev]
    self.over_threshold         = bid >= 40 ? 1 : 0
    self.rank_boost             = rank_boosts.active.sum(:amount)
  end

  def calculate_ranking_fields!
    calculate_ranking_fields
    save!
  end

  def precache_rank_scores
    rank_scores = {}
    CurrencyGroup.find_each do |currency_group|
      score = currency_group.precache_weights.keys.inject(0) { |sum, key| sum + (currency_group.precache_weights[key] * send(key)) }
      score += 5 if item_type == "ActionOffer"
      score += 10 if price == 0
      score += 10 if featured?
      rank_scores[currency_group.id] = score
    end
    rank_scores
  end
  memoize :precache_rank_scores
  
  def precache_rank_score_for(currency_group_id)
    precache_rank_scores[currency_group_id]
  end
  
  def postcache_rank_score(currency)
    self.rank_score = precache_rank_score_for(currency.currency_group_id) || 0
    self.rank_score += (categories & currency.categories).length * (currency.postcache_weights[:category_match] || 0)
    rank_score
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
  

  def postcache_reject?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version, screen_layout_size, video_offer_ids)
    geoip_reject?(geoip_data, device) ||
    already_complete?(device, app_version) ||
    show_rate_reject?(device) ||
    flixter_reject?(publisher_app, device) ||
    minimum_bid_reject?(currency, type) ||
    jailbroken_reject?(device) ||
    direct_pay_reject?(direct_pay_providers) ||
    action_app_reject?(device) ||
    min_os_version_reject?(os_version) ||
    cookie_tracking_reject?(publisher_app, library_version) ||
    screen_layout_sizes_reject?(screen_layout_size) ||
    is_disabled?(publisher_app, currency) ||
    age_rating_reject?(currency) ||
    publisher_whitelist_reject?(publisher_app) ||
    currency_whitelist_reject?(currency) ||
    video_offers_reject?(video_offer_ids, type) ||
    frequency_capping_reject?(device)
  end

  def precache_reject?(platform_name, hide_rewarded_app_installs, normalized_device_type)
    app_platform_mismatch?(platform_name) || hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) || device_platform_mismatch?(normalized_device_type)
  end
  
  def is_valid_for?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version, screen_layout_size)
    (is_test_device?(currency, device) && 
      is_test_video_offer?(type) ) ||
    (!(is_test_video_offer?(type) ||
      device_platform_mismatch?(Device.normalize_device_type(device_type)) ||
      geoip_reject?(geoip_data, device) ||
      already_complete?(device, app_version) ||
      flixter_reject?(publisher_app, device) ||
      minimum_bid_reject?(currency, type) ||
      jailbroken_reject?(device) ||
      direct_pay_reject?(direct_pay_providers) ||
      action_app_reject?(device) ||
      hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) ||
      min_os_version_reject?(os_version) ||
      cookie_tracking_reject?(publisher_app, library_version) ||
      screen_layout_sizes_reject?(screen_layout_size) ||
      is_disabled?(publisher_app, currency) ||
      app_platform_mismatch?(publisher_app) ||
      age_rating_reject?(currency) ||
      publisher_whitelist_reject?(publisher_app) ||
      currency_whitelist_reject?(currency) ||
      frequency_capping_reject?(device)) &&
      accepting_clicks?)
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
    now = Time.now.utc
    featured_offer.created_at = now
    featured_offer.updated_at = now
    featured_offer.featured = true
    featured_offer.name_suffix = "featured"
    featured_offer.bid = featured_offer.min_bid
    featured_offer.tapjoy_enabled = false
    featured_offer.save!
    featured_offer
  end

  def create_non_rewarded_clone
    non_rewarded_offer = self.clone
    now = Time.now.utc
    non_rewarded_offer.created_at = now
    non_rewarded_offer.updated_at = now
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
  
  def percentile
    self.conversion_rate = is_paid? ? (0.05 / (0.01 * price)) : 0.50 if conversion_rate == 0
    calculate_ranking_fields
    percentile_group_id = CurrencyGroup.find_by_name('percentile').id
    offers = OfferList.new(:type => percentile_type).offers.reject { |o| o.id == id }
    100 * offers.select { |o| precache_rank_score_for(percentile_group_id) >= o.precache_rank_score_for(percentile_group_id) }.length / offers.length
  end
  
  def percentile_type
    return VIDEO_OFFER_TYPE if item_type == 'VideoOffer'
    
    if featured?
      if rewarded?
        FEATURED_OFFER_TYPE
      else
        NON_REWARDED_FEATURED_OFFER_TYPE
      end
    else
      if rewarded?
        DEFAULT_OFFER_TYPE
      else
        NON_REWARDED_DISPLAY_OFFER_TYPE
      end
    end
  end
  
  def frequency_capping_reject?(device)
    return false unless multi_complete? && interval != Offer::FREQUENCIES_CAPPING_INTERVAL['none']
    
    if device.has_app?(item_id)
      device.last_run_time(item_id) + interval > Time.zone.now
    else
      false
    end
  end

private

  def is_disabled?(publisher_app, currency)
    item_id == currency.app_id ||
      currency.get_disabled_offer_ids.include?(item_id) ||
      currency.get_disabled_partner_ids.include?(partner_id) ||
      (currency.only_free_offers? && is_paid?) ||
      (self_promote_only? && partner_id != publisher_app.partner_id)
  end

  def device_platform_mismatch?(normalized_device_type)
    return false if normalized_device_type.blank?

    !get_device_types.include?(normalized_device_type)
  end

  def app_platform_mismatch?(app_platform_name)
    return false if app_platform_name.blank?
    
    platform_name = get_platform
    platform_name != 'All' && platform_name != app_platform_name
  end

  def age_rating_reject?(currency)
    return false if currency.max_age_rating.nil?
    return false if age_rating.nil?
    currency.max_age_rating < age_rating
  end

  def geoip_reject?(geoip_data, device)
    return false if EXEMPT_UDIDS.include?(device.key)

    return true if countries.present? && countries != '[]' && !get_countries.include?(geoip_data[:country])
    return true if geoip_data[:country] && get_countries_blacklist.include?(geoip_data[:country].to_s.upcase)
    return true if postal_codes.present? && postal_codes != '[]' && !get_postal_codes.include?(geoip_data[:postal_code])
    return true if cities.present? && cities != '[]' && !get_cities.include?(geoip_data[:city])

    false
  end

  def already_complete?(device, app_version = nil)
    return false if EXEMPT_UDIDS.include?(device.key) || multi_complete?
    
    app_id_for_device = item_id
    if item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(item_id, app_version)
    end

    if app_id_for_device == '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424'
      # Don't show 'Tap farm' offer to users that already have 'Tap farm', 'Tap farm 6', or 'Tap farm 5'
      return device.has_app?(app_id_for_device) || device.has_app?('bad4b0ae-8458-42ba-97ba-13b302827234') || device.has_app?('403014c2-9a1b-4c1d-8903-5a41aa09be0e')
    end

    if app_id_for_device == 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91'
      # Don't show 'Tap Store' offer to users that already have 'Tap Store', 'Tap Store Boost', or 'Tap Store Plus'
      return device.has_app?(app_id_for_device) || device.has_app?('a994587c-390c-4295-a6b6-dd27713030cb') || device.has_app?('6703401f-1cb2-42ec-a6a4-4c191f8adc27')
    end

    if app_id_for_device == '3885c044-9c8e-41d4-b136-c877915dda91'
      # don't show the beat level 2 in clubworld action to users that already have clubworld
      return device.has_app?(app_id_for_device) || device.has_app?('a3980ac5-7d33-43bc-8ba1-e4598c7ed279')
    end

    if app_id_for_device == '7f44c068-6fa1-482c-b2d2-770edcf8f83d' || app_id_for_device == '192e6d0b-cc2f-44c2-957c-9481e3c223a0'
      # there are 2 groupon apps
      return device.has_app?('7f44c068-6fa1-482c-b2d2-770edcf8f83d') || device.has_app?('192e6d0b-cc2f-44c2-957c-9481e3c223a0')
    end

    device.has_app?(app_id_for_device)
  end

  def show_rate_reject?(device)
    return false if EXEMPT_UDIDS.include?(device.key)

    srand( (device.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    should_reject = rand > show_rate
    srand

    should_reject
  end

  def flixter_reject?(publisher_app, device)
    clash_of_titans_offer_id = '4445a5be-9244-4ce7-b65d-646ee6050208'
    tap_fish_id = '9dfa6164-9449-463f-acc4-7a7c6d7b5c81'
    tap_fish_coins_id = 'b24b873f-d949-436e-9902-7ff712f7513d'
    flixter_id = 'f8751513-67f1-4273-8e4e-73b1e685e83d'

    if id == clash_of_titans_offer_id
      # Only show offer in TapFish:
      return true unless publisher_app.id == tap_fish_id || publisher_app.id == tap_fish_coins_id

      # Only show offer if user has recently run flixter:
      return true if !device.has_app?(flixter_id) || device.last_run_time(flixter_id) < (Time.zone.now - 1.days)
    end
    false
  end

  def publisher_whitelist_reject?(publisher_app)
    publisher_app_whitelist.present? && !get_publisher_app_whitelist.include?(publisher_app.id)
  end

  def currency_whitelist_reject?(currency)
    currency.use_whitelist? && !currency.get_offer_whitelist.include?(id)
  end

  def minimum_bid_reject?(currency, type)
    min_bid = case type
    when DEFAULT_OFFER_TYPE
      currency.minimum_offerwall_bid
    when FEATURED_OFFER_TYPE
      currency.minimum_featured_bid
    when DISPLAY_OFFER_TYPE
      currency.minimum_display_bid
    when NON_REWARDED_FEATURED_OFFER_TYPE
      currency.minimum_featured_bid
    when NON_REWARDED_DISPLAY_OFFER_TYPE
      currency.minimum_display_bid
    end
    min_bid.present? && bid < min_bid
  end

  def jailbroken_reject?(device)
    is_paid? && device.is_jailbroken?
  end

  def direct_pay_reject?(direct_pay_providers)
    direct_pay? && !direct_pay_providers.include?(direct_pay)
  end

  def action_app_reject?(device)
    item_type == "ActionOffer" && third_party_data.present? && !device.has_app?(third_party_data)
  end

  def min_os_version_reject?(os_version)
    return false if min_os_version.blank?
    return true if os_version.blank?

    !os_version.version_greater_than_or_equal_to?(min_os_version)
  end

  def screen_layout_sizes_reject?(screen_layout_size)
    return false if screen_layout_sizes.blank? || screen_layout_sizes == '[]'
    return true if screen_layout_size.blank?

    !get_screen_layout_sizes.include?(screen_layout_size)
  end
  
  def hide_rewarded_app_installs_reject?(hide_rewarded_app_installs)
    hide_rewarded_app_installs && rewarded? && item_type != 'GenericOffer' && item_type != 'VideoOffer'
  end

  def cookie_tracking_reject?(publisher_app, library_version)
    cookie_tracking? && publisher_app.platform == 'iphone' && !library_version.version_greater_than_or_equal_to?('8.0.3')
  end
  
  def video_offers_reject?(video_offer_ids, type)
    return false if type == Offer::VIDEO_OFFER_TYPE
    item_type == 'VideoOffer' && !video_offer_ids.include?(id)
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

  def bid_for_ranks
    [ bid, 500 ].min
  end

end
