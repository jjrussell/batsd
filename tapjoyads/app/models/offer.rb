class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord
  
  APPLE_DEVICES = %w( iphone itouch ipad )
  IPAD_DEVICES = %w( ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES
  EXEMPT_UDIDS = Set.new(['c73e730913822be833766efffc7bb1cf239d855a',
                          '7bed2150f941bad724c42413c5efa7f202c502e0',
                          'a000002256c234'])
  
  CLASSIC_OFFER_TYPE  = '0'
  DEFAULT_OFFER_TYPE  = '1'
  FEATURED_OFFER_TYPE = '2'
  DISPLAY_OFFER_TYPE  = '3'
  GROUP_SIZE = 200
  OFFER_LIST_REQUIRED_COLUMNS = [ 'id', 'item_id', 'item_type', 'partner_id',
                                  'name', 'url', 'price', 'bid', 'payment',
                                  'conversion_rate', 'show_rate', 'self_promote_only',
                                  'device_types', 'countries', 'postal_codes', 'cities',
                                  'age_rating', 'multi_complete', 'featured',
                                  'publisher_app_whitelist', 'direct_pay', 'reward_value',
                                  'third_party_data', 'payment_range_low',
                                  'payment_range_high', 'icon_id_override', 'rank_boost' ].map { |c| "#{quoted_table_name}.#{c}" }.join(', ')
  
  DEFAULT_WEIGHTS = { :conversion_rate => 1, :bid => 1, :price => -1, :avg_revenue => 5, :random => 1, :over_threshold => 6 }
  DIRECT_PAY_PROVIDERS = %w( boku paypal )
  
  DAILY_STATS_START_HOUR = 6
  DAILY_STATS_RANGE = 6
  
  attr_accessor :rank_score, :normal_conversion_rate, :normal_price, :normal_avg_revenue, :normal_bid, :offer_list_length, :user_rating, :primary_category, :action_offer_name
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  has_many :rank_boosts
  has_many :enable_offer_requests
  has_many :dependent_action_offers, :class_name => 'ActionOffer', :foreign_key => :prerequisite_offer_id
  has_many :offer_events
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url, :rank_boost
  validates_numericality_of :price, :only_integer => true
  validates_numericality_of :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_blank => false, :allow_nil => false
  validates_numericality_of :bid, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10000, :allow_blank => false, :allow_nil => false
  validates_numericality_of :min_bid_override, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :conversion_rate, :rank_boost, :greater_than_or_equal_to => 0
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :allow_blank => false, :greater_than_or_equal_to => 0
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_blank => false, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :self_promote_only, :featured, :multi_complete, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer GenericOffer OfferpalOffer RatingOffer ActionOffer )
  validates_inclusion_of :direct_pay, :allow_blank => true, :allow_nil => true, :in => DIRECT_PAY_PROVIDERS
  validates_each :countries, :cities, :postal_codes, :allow_blank => true do |record, attribute, value|
    begin
      parsed = JSON.parse(value)
      record.errors.add(attribute, 'is not an Array') unless parsed.is_a?(Array)
    rescue
      record.errors.add(attribute, 'is not valid JSON')
    end
  end
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
      record.errors.add(attribute, "is only for GenericOffers") unless record.item_type == 'GenericOffer'
      record.errors.add(attribute, "cannot be used for pay-per-click offers") if record.pay_per_click?
    end
  end
  validate :bid_higher_than_min_bid
  
  before_validation :update_payment
  before_create :set_stats_aggregation_times
  before_save :cleanup_url
  before_save :fix_country_targeting
  before_save :update_payment
  after_save :update_enabled_rating_offer_id
  after_save :update_pending_enable_requests
  
  named_scope :enabled_offers, :joins => :partner, :conditions => "tapjoy_enabled = true AND user_enabled = true AND item_type != 'RatingOffer' AND ((payment > 0 AND #{Partner.quoted_table_name}.balance > 0) OR (payment = 0 AND reward_value > 0))"
  named_scope :by_name, lambda { |offer_name| { :conditions => ["offers.name LIKE ?", "%#{offer_name}%" ] } }
  named_scope :by_device, lambda { |platform| { :conditions => ["offers.device_types LIKE ?", "%#{platform}%" ] } }
  named_scope :for_offer_list, :select => OFFER_LIST_REQUIRED_COLUMNS
  named_scope :for_display_ads, :conditions => "item_type = 'App' AND price = 0 AND conversion_rate >= 0.3 AND LENGTH(offers.name) <= 30"
  named_scope :featured, :conditions => { :featured => true }
  named_scope :free_apps, :conditions => { :item_type => 'App', :price => 0 }
  named_scope :nonfeatured, :conditions => { :featured => false }
  named_scope :visible, :conditions => { :hidden => false }
  named_scope :to_aggregate_hourly_stats, lambda { { :conditions => [ "next_stats_aggregation_time < ?", Time.zone.now ] } }
  named_scope :to_aggregate_daily_stats, lambda { { :conditions => [ "next_daily_stats_aggregation_time < ?", Time.zone.now ] } }
  named_scope :for_ios_only, :conditions => 'device_types not like "%android%"'
  named_scope :with_rank_boosts, :joins => :rank_boosts, :readonly => false
  
  delegate :balance, :pending_earnings, :name, :approved_publisher?, :to => :partner, :prefix => true
  
  alias_method :events, :offer_events
  
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
  
  def self.cache_offers
    Benchmark.realtime do
      weights = AppGroup.find_by_name('default').weights
      
      offer_list = Offer.enabled_offers.nonfeatured.for_offer_list
      cache_offer_list(offer_list, weights, DEFAULT_OFFER_TYPE, Experiments::EXPERIMENTS[:default])
  
      offer_list = Offer.enabled_offers.featured.for_offer_list + Offer.enabled_offers.nonfeatured.free_apps.for_offer_list
      cache_offer_list(offer_list, weights.merge({ :random => 0 }), FEATURED_OFFER_TYPE, Experiments::EXPERIMENTS[:default])
  
      offer_list = Offer.enabled_offers.nonfeatured.for_offer_list.for_display_ads
      cache_offer_list(offer_list, weights, DISPLAY_OFFER_TYPE, Experiments::EXPERIMENTS[:default])
    end
  end
    
  def self.cache_offer_stats
    offer_list = Offer.enabled_offers.nonfeatured.for_offer_list
    cache_offer_stats_for_offer_list(offer_list, DEFAULT_OFFER_TYPE)
    
    offer_list = Offer.enabled_offers.featured.for_offer_list + Offer.enabled_offers.nonfeatured.free_apps.for_offer_list
    cache_offer_stats_for_offer_list(offer_list, FEATURED_OFFER_TYPE)
    
    offer_list = Offer.enabled_offers.nonfeatured.for_offer_list.for_display_ads
    cache_offer_stats_for_offer_list(offer_list, DISPLAY_OFFER_TYPE)
  end
  
  def self.cache_offer_stats_for_offer_list(offer_list, type)
    conversion_rates    = offer_list.collect(&:conversion_rate)
    prices              = offer_list.collect(&:price)
    avg_revenues        = offer_list.collect(&:avg_revenue)
    bids                = offer_list.collect(&:bid)
    cvr_mean            = conversion_rates.mean
    cvr_std_dev         = conversion_rates.standard_deviation
    price_mean          = prices.mean
    price_std_dev       = prices.standard_deviation
    avg_revenue_mean    = avg_revenues.mean
    avg_revenue_std_dev = avg_revenues.standard_deviation
    bid_mean            = bids.mean
    bid_std_dev         = bids.standard_deviation
    
    stats = { :cvr_mean => cvr_mean, :cvr_std_dev => cvr_std_dev, :price_mean => price_mean, :price_std_dev => price_std_dev,
      :avg_revenue_mean => avg_revenue_mean, :avg_revenue_std_dev => avg_revenue_std_dev, :bid_mean => bid_mean, :bid_std_dev => bid_std_dev }
    
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    bucket.put("offer_rank_statistics.#{type}", Marshal.dump(stats))
    Mc.put("s3.offer_rank_statistics.#{type}", stats)
  end
  
  def self.cache_offer_list(offer_list, weights, type, exp, currency = nil)
    stats = get_offer_rank_statistics(type)
    
    offer_list.each do |offer|
      offer.normalize_stats(stats)
      offer.name = "#{offer.truncated_name}..." if offer.name.length > 40
      offer.calculate_rank_score(weights)
      if (offer.item_type == 'App' || offer.item_type == 'ActionOffer')
        offer_item             = offer.item_type.constantize.find(offer.item_id)
        offer.primary_category = offer_item.primary_category
        offer.user_rating      = offer_item.user_rating
        if offer.item_type == 'ActionOffer'
          action_app = App.find(offer_item.app_id)
          offer.action_offer_name = action_app.name
        end
      end
    end
    
    offer_list.sort! do |o1, o2|
      if o1.featured? && !o2.featured?
        -1
      elsif o2.featured? && !o1.featured?
        1
      else
        o2.rank_score <=> o1.rank_score
      end
    end
    
    offer_list.first.offer_list_length = offer_list.length
  
    offer_groups = []
    group        = 0
    key          = currency.present? ? "enabled_offers.#{currency.id}.type_#{type}.exp_#{exp}" : "enabled_offers.type_#{type}.exp_#{exp}"
    bucket       = S3.bucket(BucketNames::OFFER_DATA)
    
    offer_list.in_groups_of(GROUP_SIZE) do |offers|
      offers.compact!
      if currency.nil?
        marshalled_offers = Marshal.dump(offers)
        bucket.put("#{key}.#{group}", marshalled_offers)
      end
      offer_groups << offers
      group += 1
    end
    
    offer_groups.each_with_index do |offers, i|
      Mc.distributed_put("#{key}.#{i}", offers)
    end
  
    if currency.present?
      while Mc.distributed_get("#{key}.#{group}")
        Mc.distributed_delete("#{key}.#{group}")
        group += 1
      end
    else
      while bucket.key("#{key}.#{group}").exists?
        bucket.key("#{key}.#{group}").delete
        Mc.distributed_delete("#{key}.#{group}")
        group += 1
      end
    end

  end
  
  def self.get_cached_offers(options = {}, &block)
    type = options.delete(:type)
    exp  = options.delete(:exp)
    currency  = options.delete(:currency)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    type ||= DEFAULT_OFFER_TYPE
    exp  ||= Experiments::EXPERIMENTS[:default]
    
    offer_list        = []
    offer_list_length = nil
    group             = 0
    s3_key            = "enabled_offers.type_#{type}.exp_#{exp}"
    key               = currency.present? ? "enabled_offers.#{currency.id}.type_#{type}.exp_#{exp}" : s3_key
    
    loop do
      offers = Mc.distributed_get_and_put("#{key}.#{group}") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        if group == 0
          Marshal.restore(bucket.get("#{s3_key}.#{group}"))
        else
          []
        end
      end
      
      if block_given?
        offer_list_length ||= offers.first.offer_list_length if offers.present?
        break if yield(offers) == 'break'
      else
        offer_list += offers
      end
      
      break unless offers.length == GROUP_SIZE
      group += 1
    end
    
    block_given? ? offer_list_length.to_i : offer_list
  end
  
  def self.get_offer_rank_statistics(type)
    Mc.get_and_put("s3.offer_rank_statistics.#{type}") do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.get("offer_rank_statistics.#{type}"))
    end
  end
  
  def self.s3_udids_path(offer_id, date = nil)
    "udids/#{offer_id}/#{date && date.strftime("%Y-%m")}"
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
    conversion_rate * bid
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

  def is_primary?
    item_id == id
  end
  
  def is_secondary?
    !is_primary?
  end
  
  def is_enabled?
    tapjoy_enabled? && user_enabled? && ((payment > 0 && partner.balance > 0) || (payment == 0 && reward_value.present? && reward_value > 0))
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
  
  def get_destination_url(udid, publisher_app_id, click_key = nil, itunes_link_affiliate = 'linksynergy', currency_id = nil, language_code = nil)
    if instructions.present?
      instructions_url(udid, publisher_app_id, click_key, itunes_link_affiliate, currency_id, language_code)
    else
      complete_action_url(udid, publisher_app_id, click_key, itunes_link_affiliate, currency_id)
    end
  end
  
  def get_click_url(options)
    publisher_app     = options.delete(:publisher_app)     { |k| raise "#{k} is a required argument" }
    publisher_user_id = options.delete(:publisher_user_id) { |k| raise "#{k} is a required argument" }
    udid              = options.delete(:udid)              { |k| raise "#{k} is a required argument" }
    currency_id       = options.delete(:currency_id)       { |k| raise "#{k} is a required argument" }
    source            = options.delete(:source)            { |k| raise "#{k} is a required argument" }
    app_version       = options.delete(:app_version)       { nil }
    viewed_at         = options.delete(:viewed_at)         { |k| raise "#{k} is a required argument" }
    displayer_app_id  = options.delete(:displayer_app_id)  { nil }
    exp               = options.delete(:exp)               { nil }
    country_code      = options.delete(:country_code)      { nil }
    language_code     = options.delete(:language_code)     { nil }
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
    elsif item_type == 'ActionOffer'
      click_url += "action"
    else
      raise "click_url requested for an offer that should not be enabled. offer_id: #{id}"
    end
    
    data = {
      :advertiser_app_id => item_id,
      :publisher_app_id  => publisher_app.id,
      :publisher_user_id => publisher_user_id,
      :udid              => udid,
      :source            => source,
      :offer_id          => id,
      :app_version       => app_version,
      :viewed_at         => viewed_at.to_f,
      :currency_id       => currency_id,
      :country_code      => country_code,
      :displayer_app_id  => displayer_app_id,
      :exp               => exp,
      :language_code     => language_code
    }
    
    "#{click_url}?data=#{SymmetricCrypto.encrypt(Marshal.dump(data), SYMMETRIC_CRYPTO_SECRET).unpack("H*").first}"
  end
  
  def get_fullscreen_ad_url(options)
    publisher_app     = options.delete(:publisher_app)     { |k| raise "#{k} is a required argument" }
    publisher_user_id = options.delete(:publisher_user_id) { |k| raise "#{k} is a required argument" }
    udid              = options.delete(:udid)              { |k| raise "#{k} is a required argument" }
    currency_id       = options.delete(:currency_id)       { |k| raise "#{k} is a required argument" }
    source            = options.delete(:source)            { |k| raise "#{k} is a required argument" }
    app_version       = options.delete(:app_version)       { nil }
    viewed_at         = options.delete(:viewed_at)         { |k| raise "#{k} is a required argument" }
    displayer_app_id  = options.delete(:displayer_app_id)  { nil }
    exp               = options.delete(:exp)               { nil }
    country_code      = options.delete(:country_code)      { nil }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    ad_url = "#{API_URL}/fullscreen_ad"
    if item_type == 'TestOffer'
      ad_url += "/test_offer"
    end
    ad_url += "?advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app.id}&publisher_user_id=#{publisher_user_id}&udid=#{udid}&source=#{source}&offer_id=#{id}&app_version=#{app_version}&viewed_at=#{viewed_at.to_f}&currency_id=#{currency_id}&country_code=#{country_code}"
    ad_url += "&displayer_app_id=#{displayer_app_id}" if displayer_app_id.present?
    ad_url += "&exp=#{exp}" if exp.present?
    ad_url
  end
  
  def get_icon_url(options = {})
    Offer.get_icon_url({:icon_id => Offer.hashed_icon_id(icon_id)}.merge(options))
  end
  
  def self.get_icon_url(options = {})
    source   = options.delete(:source)   { :s3 }
    size     = options.delete(:size)     { '57' }
    icon_id  = options.delete(:icon_id)  { |k| raise "#{k} is a required argument" }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    prefix = source == :s3 ? "https://s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy" : CLOUDFRONT_URL
    
    "#{prefix}/icons/#{size}/#{icon_id}.jpg"
  end
  
  def save_icon!(icon_src_blob, small_icon_src_blob = nil)
    bucket = S3.bucket(BucketNames::TAPJOY)
    
    icon_id = Offer.hashed_icon_id(id)
    existing_icon_blob = bucket.get("icons/src/#{icon_id}.jpg") rescue ''
    
    return if Digest::MD5.hexdigest(icon_src_blob) == Digest::MD5.hexdigest(existing_icon_blob)
      
    icon_256 = Magick::Image.from_blob(icon_src_blob)[0].resize(256, 256).opaque('#ffffff00', 'white')
    medium_icon_blob = icon_256.to_blob{|i| i.format = 'JPG'}
    
    corner_mask_blob = bucket.get("display/round_mask.png")
    corner_mask = Magick::Image.from_blob(corner_mask_blob)[0].resize(256, 256)
    icon_256.composite!(corner_mask, 0, 0, Magick::CopyOpacityCompositeOp)
    icon_256 = icon_256.opaque('#ffffff00', 'white')
    icon_256.alpha(Magick::OpaqueAlphaChannel)
    
    icon_256_blob = icon_256.to_blob{|i| i.format = 'JPG'}
    icon_114_blob = icon_256.resize(114, 114).to_blob{|i| i.format = 'JPG'}
    icon_57_blob = icon_256.resize(57, 57).to_blob{|i| i.format = 'JPG'}
  
    small_icon_src_blob = icon_src_blob if small_icon_src_blob.blank?
    bucket.put("icons/#{id}.png", small_icon_src_blob, {}, "public-read")
    bucket.put("icons/medium/#{id}.jpg", medium_icon_blob, {}, "public-read")
    
    bucket.put("icons/src/#{icon_id}.jpg", icon_src_blob, {}, "public-read")
    bucket.put("icons/256/#{icon_id}.jpg", icon_256_blob, {}, "public-read")
    bucket.put("icons/114/#{icon_id}.jpg", icon_114_blob, {}, "public-read")
    bucket.put("icons/57/#{icon_id}.jpg", icon_57_blob, {}, "public-read")
  
    Mc.delete("icon.s3.#{id}")
    
    # Invalidate cloudfront
    if existing_icon_blob.present?
      begin
        acf = RightAws::AcfInterface.new
        acf.invalidate('E1MG6JDV6GH0F2', ["/icons/#{id}.png", "/icons/medium/#{id}.jpg", "/icons/256/#{icon_id}.jpg", "/icons/114/#{icon_id}.jpg", "/icons/57/#{icon_id}.jpg"], "#{id}.#{Time.now.to_i}")
      rescue Exception => e
        Notifier.alert_new_relic(FailedToInvalidateCloudfront, e.message)
      end
    end
  end
  
  def get_countries
    Set.new(countries.blank? ? nil : JSON.parse(countries))
  end
  
  def get_postal_codes
    Set.new(postal_codes.blank? ? nil : JSON.parse(postal_codes))
  end
  
  def get_cities
    Set.new(cities.blank? ? nil : JSON.parse(cities))
  end
  
  def get_device_types
    Set.new(device_types.blank? ? nil : JSON.parse(device_types))
  end

  def expected_device_types
    if item_type == 'App' || item_type == 'ActionOffer' || item_type == 'RatingOffer'
      item.is_android? ? ANDROID_DEVICES : APPLE_DEVICES
    else
      ALL_DEVICES
    end
  end

  def get_publisher_app_whitelist
    Set.new(publisher_app_whitelist.split(';'))
  end
  
  def get_platform
    d_types = get_device_types
    if d_types.length > 1 && d_types.include?('android')
      'All'
    elsif d_types.include?('android')
      'Android'
    else
      'iOS'
    end
  end

  def wrong_platform?
    if ['App', 'ActionOffer'].include?(item_type)
      case get_platform
      when 'Android'
        item.platform == 'iphone'
      when 'iOS'
        item.platform == 'android'
      else
        true # should never be "All" for apps
      end
    end
  end

  def normalize_stats(stats)
    self.normal_conversion_rate = (stats[:cvr_std_dev] == 0) ? 0 : (conversion_rate - stats[:cvr_mean]) / stats[:cvr_std_dev]
    self.normal_price           = (stats[:price_std_dev] == 0) ? 0 : (price - stats[:price_mean]) / stats[:price_std_dev]
    self.normal_avg_revenue     = (stats[:avg_revenue_std_dev] == 0) ? 0 : (avg_revenue - stats[:avg_revenue_mean]) / stats[:avg_revenue_std_dev]
    self.normal_bid             = (stats[:bid_std_dev] == 0) ? 0 : (bid - stats[:bid_mean]) / stats[:bid_std_dev]
  end
  
  def calculate_rank_score(rank_weights = {})
    weights = rank_weights.clone
    random_weight = weights.delete(:random) { 0 }
    boost_weight = weights.delete(:boost) { 1 }
    over_threshold_weight = weights.delete(:over_threshold) { 0 }
    weights = { :conversion_rate => 0, :price => 0, :avg_revenue => 0, :bid => 0 }.merge(weights)
    self.rank_score = weights.keys.inject(0) { |sum, key| sum + (weights[key] * send("normal_#{key}")) }
    self.rank_score += rand * random_weight
    self.rank_score += rank_boost * boost_weight
    self.rank_score += over_threshold_weight if bid >= 40
    self.rank_score += 5 if item_type == "ActionOffer"
    self.rank_score += 10 if price == 0
  end
  
  def estimated_percentile
    if @estimated_percentile.nil? || changed?
      @estimated_percentile = recalculate_estimated_percentile
    end
    @estimated_percentile
  end
  
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
  
  def should_reject?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers, type, hide_app_installs)
    return should_reject_from_app_or_currency?(publisher_app, currency) ||
        device_platform_mismatch?(publisher_app, device_type)
        geoip_reject?(geoip_data, device) ||
        already_complete?(publisher_app, device, app_version) ||
        show_rate_reject?(device) ||
        flixter_reject?(publisher_app, device) ||
        minimum_featured_bid_reject?(currency, type) ||
        jailbroken_reject?(device) ||
        direct_pay_reject?(direct_pay_providers) ||
        action_app_reject?(device) ||
        capped_installs_reject?(publisher_app) ||
        hide_app_installs_reject?(currency, hide_app_installs)
  end
  
  def should_reject_from_app_or_currency?(publisher_app, currency)
    is_disabled?(publisher_app, currency) || app_platform_mismatch?(publisher_app) || age_rating_reject?(currency) || publisher_whitelist_reject?(publisher_app) || currency_whitelist_reject?(currency)
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
      if featured?
        is_paid? ? price : 65
      else
        is_paid? ? (price * 0.50).round : 35
        # uncomment for tapjoy premier & change show.html line 92-ish
        # is_paid? ? (price * 0.65).round : 50
      end
    elsif item_type == 'ActionOffer'
      get_platform == 'Android' ? 25 : 35
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
  
  def budget_may_not_be_met?
    (daily_budget > 0) && needs_higher_bid?
  end
  
  def needs_higher_bid?
    !self_promote_only? && rank_boost == 0 && (bid_is_bad? || bid_is_passable?)
  end
  
  def needs_more_funds?
    show_rate != 1 && (daily_budget == 0 || (daily_budget > 0 && low_balance?))
  end
  
  def on_track_for_budget?
    show_rate != 1 && !needs_more_funds?
  end
  
  def bid_is_good?
    show_rate == 1 && estimated_percentile >= 85
  rescue
    false
  end
  
  def bid_is_passable?
    show_rate == 1 && estimated_percentile >= 50 && estimated_percentile < 85
  rescue
    false
  end
  
  def bid_is_bad?
    show_rate == 1 && estimated_percentile < 50
  rescue
    false
  end
  
  def bid_for_percentile(percentile_goal)
    while estimated_percentile < percentile_goal do
      self.bid += 1
      update_payment(true)
    end
    recommended_bid = bid
    self.bid = bid_was
    self.payment = payment_was
    @estimated_percentile = recalculate_estimated_percentile
    recommended_bid
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
  
  def free_app?
    item_type == 'App' && price == 0
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
  
  def instructions_url(udid, publisher_app_id, click_key, itunes_link_affiliate, currency_id, language_code)
    data = {
      :id                    => id,
      :udid                  => udid,
      :publisher_app_id      => publisher_app_id,
      :click_key             => click_key,
      :itunes_link_affiliate => itunes_link_affiliate,
      :currency_id           => currency_id,
      :language_code         => language_code
    }
    
    "#{API_URL}/offer_instructions?data=#{SymmetricCrypto.encrypt(Marshal.dump(data), SYMMETRIC_CRYPTO_SECRET).unpack("H*").first}"
  end
  
  def complete_action_url(udid, publisher_app_id, click_key, itunes_link_affiliate, currency_id)
    final_url = url.gsub('TAPJOY_UDID', udid.to_s)
    if item_type == 'App' && final_url =~ /^http:\/\/phobos\.apple\.com/
      if itunes_link_affiliate == 'tradedoubler'
        final_url += '&partnerId=2003&tduid=UK1800811'
      else
        final_url = "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&type=10&tmpid=3909&RD_PARM1=#{CGI::escape(final_url)}"
      end
    elsif item_type == 'EmailOffer'
      final_url += "&publisher_app_id=#{publisher_app_id}"
    elsif item_type == 'GenericOffer'
      final_url.gsub!('TAPJOY_GENERIC', click_key.to_s)
    elsif item_type == 'ActionOffer'
      final_url = url
    end
    
    final_url
  end
  
  def calculate_rank_boost!
    update_attribute(:rank_boost, rank_boosts.active.sum(:amount))
  end

private
  
  def is_disabled?(publisher_app, currency)
    return item_id == currency.app_id || 
        currency.get_disabled_offer_ids.include?(item_id) || 
        currency.get_disabled_partner_ids.include?(partner_id) ||
        (currency.only_free_offers? && is_paid?) ||
        (self_promote_only? && partner_id != publisher_app.partner_id)
  end
  
  def device_platform_mismatch?(publisher_app, device_type_param)
    device_type = normalize_device_type(device_type_param)
    
    if device_type.nil?
      if publisher_app.platform == 'android'
        device_type = 'android'
      else
        device_type = 'itouch'
      end
    end
    
    return !get_device_types.include?(device_type)
  end
  
  def app_platform_mismatch?(publisher_app)
    platform_name = get_platform
    platform_name != 'All' && platform_name != publisher_app.platform_name
  end
  
  def age_rating_reject?(currency)
    return false if currency.max_age_rating.nil?
    return false if age_rating.nil?
    return currency.max_age_rating < age_rating
  end
  
  def geoip_reject?(geoip_data, device)
    return false if EXEMPT_UDIDS.include?(device.key)

    return true if !countries.blank? && countries != '[]' && !get_countries.include?(geoip_data[:country])
    return true if !postal_codes.blank? && postal_codes != '[]' && !get_postal_codes.include?(geoip_data[:postal_code])
    return true if !cities.blank? && cities != '[]' && !get_cities.include?(geoip_data[:city])
        
    return false
  end
  
  def already_complete?(publisher_app, device, app_version)
    return false if EXEMPT_UDIDS.include?(device.key) || multi_complete?
    
    app_id_for_device = item_id
    if item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(item_id, app_version)
    end
    
    if app_id_for_device == '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424'
      # Don't show 'Tap farm' offer to users that already have 'Tap farm', 'Tap farm 6', or 'Tap farm 5'
      return device.has_app(app_id_for_device) || device.has_app('bad4b0ae-8458-42ba-97ba-13b302827234') || device.has_app('403014c2-9a1b-4c1d-8903-5a41aa09be0e')
    end
    
    if app_id_for_device == 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91'
      # Don't show 'Tap Store' offer to users that already have 'Tap Store', 'Tap Store Boost', or 'Tap Store Plus'
      return device.has_app(app_id_for_device) || device.has_app('a994587c-390c-4295-a6b6-dd27713030cb') || device.has_app('6703401f-1cb2-42ec-a6a4-4c191f8adc27')
    end
    
    if app_id_for_device == '3885c044-9c8e-41d4-b136-c877915dda91'
      # don't show the beat level 2 in clubworld action to users that already have clubworld
      return device.has_app(app_id_for_device) || device.has_app('a3980ac5-7d33-43bc-8ba1-e4598c7ed279')
    end
    
    return device.has_app(app_id_for_device)
  end
  
  def show_rate_reject?(device)
    return false if EXEMPT_UDIDS.include?(device.key)
    
    srand( (device.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    should_reject = rand > show_rate
    srand
    
    return should_reject
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
      return true if !device.has_app(flixter_id) || device.last_run_time(flixter_id) < (Time.zone.now - 1.days)
    end
    return false
  end
  
  def publisher_whitelist_reject?(publisher_app)
    return publisher_app_whitelist.present? && !get_publisher_app_whitelist.include?(publisher_app.id)
  end
  
  def currency_whitelist_reject?(currency)
    return currency.use_whitelist? && !currency.get_offer_whitelist.include?(id)
  end
  
  def minimum_featured_bid_reject?(currency, type)
    return false unless (type == FEATURED_OFFER_TYPE && currency.minimum_featured_bid)
    bid < currency.minimum_featured_bid
  end
  
  def jailbroken_reject?(device)
    is_paid? && device.is_jailbroken?
  end
  
  def direct_pay_reject?(direct_pay_providers)
    return direct_pay? && !direct_pay_providers.include?(direct_pay)
  end
  
  def action_app_reject?(device)
    item_type == "ActionOffer" && third_party_data.present? && !device.has_app(third_party_data)
  end
  
  def capped_installs_reject?(publisher_app)
    free_app? && publisher_app.capped_advertiser_app_ids.include?(item_id)
  end
  
  def hide_app_installs_reject?(currency, hide_app_installs)
    hide_app_installs && item_type != 'GenericOffer'
  end
  
  def normalize_device_type(device_type_param)
    if device_type_param =~ /iphone/i
      'iphone'
    elsif device_type_param =~ /ipod/i
      'itouch'
    elsif device_type_param =~ /ipad/i
      'ipad'
    elsif device_type_param =~ /android/i
      'android'
    else
      nil
    end
  end
  
  def cleanup_url
    self.url = url.gsub(" ", "%20")
  end
  
  def set_stats_aggregation_times
    now = Time.now.utc
    self.next_stats_aggregation_time = now if next_stats_aggregation_time.blank?
    self.next_daily_stats_aggregation_time = (now + 1.day).beginning_of_day + DAILY_STATS_START_HOUR.hours + rand(DAILY_STATS_RANGE.hours) if next_daily_stats_aggregation_time.blank?
  end
  
  def recalculate_estimated_percentile
    weights = DEFAULT_WEIGHTS
    if conversion_rate == 0
      self.conversion_rate = is_paid? ? (0.05 / (0.01 * price)) : 0.50
    end
    
    if featured?
      @stats ||= Offer.get_offer_rank_statistics(FEATURED_OFFER_TYPE)
      normalize_stats(@stats)
      calculate_rank_score(weights.merge({ :random => 0 }))
      @ranked_offers ||= Offer.get_cached_offers({ :type => FEATURED_OFFER_TYPE }).reject { |offer| offer.rank_boost > 0 || offer.id == self.id }
    else
      @stats ||= Offer.get_offer_rank_statistics(DEFAULT_OFFER_TYPE)
      normalize_stats(@stats)
      calculate_rank_score(weights.merge({ :random => 0 }))
      self.rank_score += weights[:random] * 0.5
      @ranked_offers ||= Offer.get_cached_offers({ :type => DEFAULT_OFFER_TYPE }).reject { |offer| offer.rank_boost > 0 || offer.id == self.id }
    end
    
    worse_offers = @ranked_offers.select { |offer| offer.rank_score < rank_score }
    100 * worse_offers.size / @ranked_offers.size
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
