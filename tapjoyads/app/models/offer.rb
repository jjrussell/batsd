class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  
  APPLE_DEVICES = %w( iphone itouch ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES
  EXEMPT_UDIDS = Set.new(['c73e730913822be833766efffc7bb1cf239d855a',
                          '7bed2150f941bad724c42413c5efa7f202c502e0',
                          '354957032544960', '354635032977030',
                          '357988020276502', 'a000002256c234'])
  
  CLASSIC_OFFER_TYPE  = '0'
  DEFAULT_OFFER_TYPE  = '1'
  FEATURED_OFFER_TYPE = '2'
  
  NUM_MEMCACHE_KEYS = 30
  
  attr_accessor :rank_score, :normal_conversion_rate, :normal_payment, :normal_price, :normal_show_rate, :normal_avg_revenue
  cattr_accessor :rank_weights
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  has_many :rank_boosts
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url, :instructions, :time_delay
  validates_numericality_of :price, :ordinal, :only_integer => true
  validates_numericality_of :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_blank => false, :allow_nil => false
  validates_numericality_of :actual_payment, :only_integer => true, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :allow_blank => false, :greater_than_or_equal_to => 0
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_blank => false, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :credit_card_required, :self_promote_only, :featured, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer GenericOffer OfferpalOffer RatingOffer )
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
  validates_each :payment do |record, attribute, value|
    if record.payment_changed? || record.min_payment_changed?
      if value > 0 && value < record.min_payment.to_i
        record.errors.add(attribute, "is below the minimum")
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
  
  before_create :set_stats_aggregation_times
  before_save :cleanup_url
  after_save :update_memcached
  before_destroy :clear_memcached
  
  named_scope :enabled_offers, :joins => :partner, :conditions => "payment > 0 AND tapjoy_enabled = true AND user_enabled = true AND ((partners.balance > 0 AND item_type IN ('App', 'EmailOffer', 'GenericOffer')) OR item_type = 'RatingOffer')"
  named_scope :by_ordinal, :order => 'ordinal ASC'
  named_scope :featured, :conditions => { :featured => true }
  named_scope :nonfeatured, :conditions => { :featured => false }
  named_scope :visible, :conditions => { :hidden => false }
  named_scope :to_aggregate_stats, lambda { { :conditions => ["next_stats_aggregation_time < ?", Time.zone.now], :order => "next_stats_aggregation_time ASC" } }
  
  def self.get_enabled_offers(exp = nil)
    if exp == Experiments::EXPERIMENTS[:rank_without_ordinal]
      Mc.get_and_put("s3.enabled_offers_#{rand(NUM_MEMCACHE_KEYS) * 123123}.rank_without_ordinal") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.get('enabled_offers.rank_without_ordinal'))
      end
    elsif exp == Experiments::EXPERIMENTS[:using_rank_score]
      Mc.get_and_put("s3.enabled_offers_#{rand(NUM_MEMCACHE_KEYS) * 123123}.using_rank_score") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.get('enabled_offers.using_rank_score'))
      end
    else
      Mc.get_and_put("s3.enabled_offers_#{rand(NUM_MEMCACHE_KEYS) * 123123}") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.get('enabled_offers'))
      end
    end
  end
  
  def self.get_featured_offers
    Mc.get_and_put('s3.featured_offers') do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.get('featured_offers'))
    end
  end
  
  def self.cache_enabled_offers
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    offer_list = Offer.enabled_offers.nonfeatured.by_ordinal
    
    offer_list.each do |o|
      o.adjust_cvr_for_ranking
    end
    
    offer_list.sort! do |o1, o2|
      if o1.ordinal == o2.ordinal
        o2.conversion_rate <=> o1.conversion_rate
      else
        o1.ordinal <=> o2.ordinal
      end
    end
    
    marshalled_offer_list = Marshal.dump(offer_list)
    bucket.put('enabled_offers', marshalled_offer_list)
    NUM_MEMCACHE_KEYS.times do |i|
      Mc.put("s3.enabled_offers_#{i * 123123}", offer_list)
    end
    
    # cache the experimental offers too
    cache_enabled_offers_rank_without_ordinal
    cache_enabled_offers_using_rank_score
  end
  
  def self.cache_enabled_offers_rank_without_ordinal
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    offer_list = Offer.enabled_offers.nonfeatured
    
    offer_list.each do |o|
      o.adjust_cvr_for_ranking
    end
    
    offer_list.sort! do |o1, o2|
      o2.conversion_rate <=> o1.conversion_rate
    end
    
    marshalled_offer_list = Marshal.dump(offer_list)
    bucket.put('enabled_offers.rank_without_ordinal', marshalled_offer_list)
    NUM_MEMCACHE_KEYS.times do |i|
      Mc.put("s3.enabled_offers_#{i * 123123}.rank_without_ordinal", offer_list)
    end
  end
  
  def self.cache_enabled_offers_using_rank_score
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    offer_list = Offer.enabled_offers.nonfeatured
    
    conversion_rates    = offer_list.collect(&:conversion_rate)
    payments            = offer_list.collect(&:payment)
    prices              = offer_list.collect(&:price)
    show_rates          = offer_list.collect(&:show_rate)
    avg_revenues        = offer_list.collect(&:avg_revenue)
    cvr_mean            = conversion_rates.mean
    cvr_std_dev         = conversion_rates.standard_deviation
    payment_mean        = payments.mean
    payment_std_dev     = payments.standard_deviation
    price_mean          = prices.mean
    price_std_dev       = prices.standard_deviation
    show_rate_mean      = show_rates.mean
    show_rate_std_dev   = show_rates.standard_deviation
    avg_revenue_mean    = avg_revenues.mean
    avg_revenue_std_dev = avg_revenues.standard_deviation
    
    offer_list.each do |offer|
      offer.normal_conversion_rate = (offer.conversion_rate - cvr_mean) / cvr_std_dev
      offer.normal_payment         = (offer.payment - payment_mean) / payment_std_dev
      offer.normal_price           = (offer.price - price_mean) / price_std_dev
      offer.normal_show_rate       = (offer.show_rate - show_rate_mean) / show_rate_std_dev
      offer.normal_avg_revenue     = (offer.avg_revenue - avg_revenue_mean) / avg_revenue_std_dev
      offer.calculate_rank_score({ :conversion_rate => 1, :payment => 1, :price => -1, :show_rate => 0.3, :avg_revenue => 5, :random => 1 })
    end
    
    offer_list.sort! do |o1, o2|
      o2.rank_score <=> o1.rank_score
    end
    
    marshalled_offer_list = Marshal.dump(offer_list)
    bucket.put('enabled_offers.using_rank_score', marshalled_offer_list)
    NUM_MEMCACHE_KEYS.times do |i|
      Mc.put("s3.enabled_offers_#{i * 123123}.using_rank_score", offer_list)
    end
  end
  
  def self.cache_featured_offers
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    offer_list = Offer.enabled_offers.featured.by_ordinal
    marshalled_offer_list = Marshal.dump(offer_list)
    bucket.put('featured_offers', marshalled_offer_list)
    Mc.put('s3.featured_offers', offer_list)
  end
  
  def self.find_in_cache(id)
    Mc.get_and_put("mysql.offer.#{id}") { Offer.find(id) }
  end
  
  def self.s3_udids_path(offer_id, date = nil)
    "udids/#{offer_id}/#{date && date.strftime("%Y-%m")}"
  end
  
  def find_associated_offers
    Offer.find(:all, :conditions => ["item_id = ? and id != ?", item_id, id])
  end
  
  def visual_cost
    if price <= 0
      'Free'
    elsif price <= 100
      '$'
    elsif price <= 200
      '$$'
    elsif price <= 300
      '$$$'
    else
      '$$$$'
    end
  end

  def is_publisher_offer?
    item_type == 'App' && item.currency.present?
  end

  def avg_revenue
    conversion_rate * payment
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
  
  def is_primary?
    item_id == id
  end
  
  def is_secondary?
    !is_primary?
  end
  
  def is_enabled?
    tapjoy_enabled? && user_enabled? && partner.balance > 0
  end
  
  def has_variable_payment?
    payment_range_low.present? && payment_range_high.present?
  end
  
  def get_destination_url(udid, publisher_app_id, click_key = nil, itunes_link_affiliate = 'linksynergy')
    final_url = url.gsub('TAPJOY_UDID', udid.to_s)
    if (item_type == 'App' || item_type == 'RatingOffer') && final_url =~ /phobos\.apple\.com/
      if itunes_link_affiliate == 'tradedoubler'
        final_url += '&partnerId=2003&tduid=UK1800811'
      else
        final_url = "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&type=10&tmpid=3909&RD_PARM1=#{CGI::escape(final_url)}"
      end
    elsif item_type == 'EmailOffer'
      final_url += "&publisher_app_id=#{publisher_app_id}"
    elsif item_type == 'GenericOffer'
      final_url.gsub!('TAPJOY_GENERIC', click_key.to_s)
    end
    
    final_url
  end
  
  def get_click_url(publisher_app, publisher_user_id, udid, source, app_version, viewed_at, displayer_app_id = nil, exp = nil)
    click_url = "http://ws.tapjoyads.com/click/"
    if item_type == 'App' || item_type == 'EmailOffer'
      click_url += "app?"
    elsif item_type == 'GenericOffer'
      click_url += "generic?"
    elsif item_type == 'RatingOffer'
      click_url += "rating?"
    else
      raise "click_url requested for an offer that should not be enabled. offer_id: #{id}"
    end
    click_url += "advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app.id}&publisher_user_id=#{publisher_user_id}&udid=#{udid}&source=#{source}&offer_id=#{id}&app_version=#{app_version}&viewed_at=#{viewed_at.to_f}"
    click_url += "&displayer_app_id=#{displayer_app_id}" if displayer_app_id.present?
    click_url += "&exp=#{exp}" if exp.present?
    click_url
  end
  
  def get_fullscreen_ad_url(publisher_app, publisher_user_id, udid, source, app_version, viewed_at, displayer_app_id = nil, exp = nil)
    ad_url = "http://ws.tapjoyads.com/fullscreen_ad?"
    ad_url += "advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app.id}&publisher_user_id=#{publisher_user_id}&udid=#{udid}&source=#{source}&offer_id=#{id}&app_version=#{app_version}&viewed_at=#{viewed_at.to_f}"
    ad_url += "&displayer_app_id=#{displayer_app_id}" if displayer_app_id.present?
    ad_url += "&exp=#{exp}" if exp.present?
    ad_url
  end
  
  def get_icon_url(protocol = 'http://', base64 = false)
    if base64
      url = "#{protocol}ws.tapjoyads.com/get_app_image/icon?app_id=#{item_id}"
    else
      url = "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}app_data/icons/#{item_id}.png"
    end
    url
  end
  
  def get_large_icon_url(protocol = 'http://')
    "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}app_data/icons/large/#{item_id}.png"
  end
  
  def get_medium_icon_url(protocol = 'http://')
    "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}app_data/icons/medium/#{item_id}.jpg"
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
  
  def adjust_cvr_for_ranking
    srand( (id + (Time.now.to_f / 20.minutes).to_i.to_s).hash )

    if pay_per_click?
      self.conversion_rate = 0.65 + rand * 0.15
    elsif is_paid?
      if rand < 0.02
        self.conversion_rate = 0.5
      else
        self.conversion_rate = conversion_rate + (rand * 0.15)
      end
    end
  end
  
  def calculate_rank_score(weights = {})
    random_weight = weights.delete(:random) { 0 }
    boost_weight = weights.delete(:boost) { 1 }
    weights = { :conversion_rate => 0, :payment => 0, :price => 0, :show_rate => 0, :avg_revenue => 0 }.merge(weights)
    self.rank_score = weights.keys.inject(0) { |sum, key| sum + (weights[key] * send("normal_#{key}")) }
    self.rank_score += rand * random_weight
    self.rank_score += rank_boosts.active.sum(:amount) * boost_weight
  end
  
  def name_with_suffix
    name_suffix.blank? ? name : "#{name} -- #{name_suffix}"
  end
  
  def search_result_name
    search_name = name_with_suffix
    search_name += " (active)" if is_enabled?
    search_name += " (hidden)" if hidden?
    search_name
  end
  
  def should_reject?(publisher_app, device_app_list, currency, device_type, geoip_data, app_version, reject_rating_offer)
    return is_disabled?(publisher_app, currency) ||
        platform_mismatch?(publisher_app, device_type) ||
        geoip_reject?(geoip_data, device_app_list) ||
        age_rating_reject?(currency) ||
        rating_offer_reject?(publisher_app, reject_rating_offer) ||
        already_complete?(publisher_app, device_app_list, app_version) ||
        show_rate_reject?(device_app_list) ||
        flixter_reject?(publisher_app, device_app_list) ||
        whitelist_reject?(publisher_app) ||
        gamevil_reject?(publisher_app)
  end
  
private
  
  def is_disabled?(publisher_app, currency)
    return item_id == currency.app_id || 
        currency.get_disabled_offer_ids.include?(item_id) || 
        currency.get_disabled_partner_ids.include?(partner_id) ||
        (currency.only_free_offers? && is_paid?) ||
        (self_promote_only? && partner_id != publisher_app.partner_id)
  end
  
  def platform_mismatch?(publisher_app, device_type_param)
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
  
  def age_rating_reject?(currency)
    return false if currency.max_age_rating.nil?
    return false if age_rating.nil?
    return currency.max_age_rating < age_rating
  end
  
  def geoip_reject?(geoip_data, device_app_list)
    return false if EXEMPT_UDIDS.include?(device_app_list.key)

    return true if !countries.blank? && countries != '[]' && !get_countries.include?(geoip_data[:country])
    return true if !postal_codes.blank? && postal_codes != '[]' && !get_postal_codes.include?(geoip_data[:postal_code])
    return true if !cities.blank? && cities != '[]' && !get_cities.include?(geoip_data[:city])
        
    return false
  end
  
  def already_complete?(publisher_app, device_app_list, app_version)
    return false if EXEMPT_UDIDS.include?(device_app_list.key)
    
    id_for_device_app_list = item_id
    if item_type == 'RatingOffer'
      id_for_device_app_list = RatingOffer.get_id_for_device_app_list(item_id, app_version)
    end
    
    if id_for_device_app_list == '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424'
      # Don't show 'Tap farm' offer to users that already have 'Tap farm', 'Tap farm 6', or 'Tap farm 5'
      return device_app_list.has_app(id_for_device_app_list) || device_app_list.has_app('bad4b0ae-8458-42ba-97ba-13b302827234') || device_app_list.has_app('403014c2-9a1b-4c1d-8903-5a41aa09be0e')
    end
    
    if id_for_device_app_list == 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91'
      # Don't show 'Tap Store' offer to users that already have 'Tap Store', 'Tap Store Boost', or 'Tap Store Plus'
      return device_app_list.has_app(id_for_device_app_list) || device_app_list.has_app('a994587c-390c-4295-a6b6-dd27713030cb') || device_app_list.has_app('6703401f-1cb2-42ec-a6a4-4c191f8adc27')
    end
    
    return device_app_list.has_app(id_for_device_app_list)
  end
  
  def show_rate_reject?(device_app_list)
    return false if EXEMPT_UDIDS.include?(device_app_list.key)
    
    srand( (device_app_list.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    return rand > show_rate
  end
  
  #TO REMOVE
  def gamevil_reject?(publisher_app)
    return publisher_app.partner_id == 'cea789f9-7741-4197-9cc0-c6ac40a0801a' && partner_id != 'cea789f9-7741-4197-9cc0-c6ac40a0801a'
  end
  
  def flixter_reject?(publisher_app, device_app_list)
    clash_of_titans_offer_id = '4445a5be-9244-4ce7-b65d-646ee6050208'
    tap_fish_id = '9dfa6164-9449-463f-acc4-7a7c6d7b5c81'
    tap_fish_coins_id = 'b24b873f-d949-436e-9902-7ff712f7513d'
    flixter_id = 'f8751513-67f1-4273-8e4e-73b1e685e83d'
    
    if id == clash_of_titans_offer_id
      # Only show offer in TapFish:
      return true unless publisher_app.id == tap_fish_id || publisher_app.id == tap_fish_coins_id
      
      # Only show offer if user has recently run flixter:
      return true if !device_app_list.has_app(flixter_id) || device_app_list.last_run_time(flixter_id) < (Time.zone.now - 1.days)
    end
    return false
  end
  
  def rating_offer_reject?(publisher_app, reject_rating_offer)
    return item_type == 'RatingOffer' && (reject_rating_offer || third_party_data != publisher_app.id)
  end
  
  def whitelist_reject?(publisher_app)
    return !publisher_app_whitelist.blank? && !get_publisher_app_whitelist.include?(publisher_app.id)
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

  def update_memcached
    Mc.put("mysql.offer.#{id}", self)
  end
  
  def clear_memcached
    Mc.delete("mysql.offer.#{id}")
  end
  
  def cleanup_url
    self.url = url.gsub(" ", "%20")
  end
  
  def set_stats_aggregation_times
    self.next_stats_aggregation_time = Time.zone.now if next_stats_aggregation_time.blank?
    self.stats_aggregation_interval = 3600 if stats_aggregation_interval.blank?
  end
  
end
