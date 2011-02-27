require 'rank_boost'

class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord
  
  APPLE_DEVICES = %w( iphone itouch ipad )
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
                                  'payment_range_high' ].map { |c| "#{quoted_table_name}.#{c}" }.join(', ')
  
  DEFAULT_WEIGHTS = { :conversion_rate => 1, :bid => 1, :price => -1, :avg_revenue => 5, :random => 1, :over_threshold => 6 }
  DIRECT_PAY_PROVIDERS = %w( boku paypal )
  
  attr_accessor :rank_score, :normal_conversion_rate, :normal_price, :normal_avg_revenue, :normal_bid, :rank_boost, :offer_list_length
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  has_many :rank_boosts
  has_many :enable_offer_requests
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url
  validates_numericality_of :price, :only_integer => true
  validates_numericality_of :bid, :payment, :daily_budget, :overall_budget, :only_integer => true, :greater_than_or_equal_to => 0, :allow_blank => false, :allow_nil => false
  validates_numericality_of :min_bid_override, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :min_conversion_rate, :allow_nil => true, :allow_blank => false, :greater_than_or_equal_to => 0
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_numericality_of :payment_range_low, :payment_range_high, :only_integer => true, :allow_blank => false, :allow_nil => true, :greater_than => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :credit_card_required, :self_promote_only, :featured, :multi_complete, :in => [ true, false ]
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
  
  before_create :set_stats_aggregation_times
  before_save :cleanup_url
  before_save :update_payment
  after_save :update_enabled_rating_offer_id
  after_save :check_enable_request
  
  named_scope :enabled_offers, :joins => :partner, :conditions => "tapjoy_enabled = true AND user_enabled = true AND item_type != 'RatingOffer' AND ((payment > 0 AND #{Partner.quoted_table_name}.balance > 0) OR (payment = 0 AND reward_value > 0))"
  named_scope :for_offer_list, :select => OFFER_LIST_REQUIRED_COLUMNS
  named_scope :for_display_ads, :conditions => "item_type = 'App' AND price = 0 AND conversion_rate >= 0.5"
  named_scope :featured, :conditions => { :featured => true }
  named_scope :nonfeatured, :conditions => { :featured => false }
  named_scope :visible, :conditions => { :hidden => false }
  named_scope :to_aggregate_stats, lambda { { :conditions => ["next_stats_aggregation_time < ?", Time.zone.now], :order => "next_stats_aggregation_time ASC" } }
  
  def self.redistribute_stats_aggregation(range = 1.hour)
    Benchmark.realtime do
      now = Time.zone.now + 15.minutes
      Offer.find_each do |o|
        o.next_stats_aggregation_time = now + rand(range)
        o.save(false)
      end
    end
  end
  
  def self.cache_offers
    Benchmark.realtime do
      offer_list = Offer.enabled_offers.nonfeatured.for_offer_list
      cache_offer_list(offer_list, DEFAULT_WEIGHTS, DEFAULT_OFFER_TYPE, Experiments::EXPERIMENTS[:default])
    
      offer_list = Offer.enabled_offers.featured.for_offer_list
      cache_offer_list(offer_list, DEFAULT_WEIGHTS.merge({ :random => 0 }), FEATURED_OFFER_TYPE, Experiments::EXPERIMENTS[:default])
    
      offer_list = Offer.enabled_offers.nonfeatured.for_offer_list.for_display_ads
      cache_offer_list(offer_list, DEFAULT_WEIGHTS, DISPLAY_OFFER_TYPE, Experiments::EXPERIMENTS[:default])
    end
  end
  
  def self.cache_offer_list(offer_list, weights, type, exp)
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
    bucket.put("offer_rank_statistics.type_#{type}.exp_#{exp}", Marshal.dump(stats))
    Mc.put("s3.offer_rank_statistics.type_#{type}.exp_#{exp}", stats)
    
    offer_list.each do |offer|
      offer.normalize_stats(stats)
      offer.name = "#{offer.name[0, 40].strip}..." if offer.name.length > 40
    end
    
    offer_list.each do |offer|
      offer.calculate_rank_score(weights)
    end
    
    offer_list.sort! do |o1, o2|
      o2.rank_score <=> o1.rank_score
    end
    
    offer_list.first.offer_list_length = offer_list.length
    
    offer_groups = []
    group        = 0
    bucket       = S3.bucket(BucketNames::OFFER_DATA)
    offer_list.in_groups_of(GROUP_SIZE) do |offers|
      offers.compact!
      marshalled_offers = Marshal.dump(offers)
      bucket.put("enabled_offers.type_#{type}.exp_#{exp}.#{group}", marshalled_offers)
      offer_groups << offers
      group += 1
    end
    offer_groups.each_with_index do |offers, i|
      Mc.distributed_put("s3.enabled_offers.type_#{type}.exp_#{exp}.#{i}", offers)
    end
    
    while bucket.key("enabled_offers.type_#{type}.exp_#{exp}.#{group}").exists?
      bucket.key("enabled_offers.type_#{type}.exp_#{exp}.#{group}").delete
      Mc.distributed_delete("s3.enabled_offers.type_#{type}.exp_#{exp}.#{group}")
      group += 1
    end
  end
  
  def self.get_cached_offers(options = {})
    type = options.delete(:type)
    exp  = options.delete(:exp)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    type ||= DEFAULT_OFFER_TYPE
    exp  ||= Experiments::EXPERIMENTS[:default]
    
    offer_list        = []
    offer_list_length = nil
    group             = 0
    loop do
      offers = Mc.distributed_get_and_put("s3.enabled_offers.type_#{type}.exp_#{exp}.#{group}") do
        bucket = S3.bucket(BucketNames::OFFER_DATA)
        Marshal.restore(bucket.get("enabled_offers.type_#{type}.exp_#{exp}.#{group}")) rescue []
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
  
  def self.get_offer_rank_statistics(type, exp = nil)
    exp ||= Experiments::EXPERIMENTS[:default]
    Mc.get_and_put("s3.offer_rank_statistics.type_#{type}.exp_#{exp}") do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.get("offer_rank_statistics.type_#{type}.exp_#{exp}"))
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
    item_type == 'App' && item.primary_currency.present?
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
  
  def get_destination_url(udid, publisher_app_id, click_key = nil, itunes_link_affiliate = 'linksynergy', currency_id = nil)
    final_url = url.gsub('TAPJOY_UDID', udid.to_s)
    if item_type == 'App' && final_url =~ /phobos\.apple\.com/
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
      final_url += "?currency_id=#{currency_id}&advertiser_app_id=#{third_party_data}"
    end
    
    final_url
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
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    click_url = "#{API_URL}/click/"
    if item_type == 'App' || item_type == 'EmailOffer'
      click_url += "app?"
    elsif item_type == 'GenericOffer'
      click_url += "generic?"
    elsif item_type == 'RatingOffer'
      click_url += "rating?"
    elsif item_type == 'TestOffer'
      click_url += "test_offer?"
    elsif item_type == 'ActionOffer'
      click_url += "action?"
    else
      raise "click_url requested for an offer that should not be enabled. offer_id: #{id}"
    end
    click_url += "advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app.id}&publisher_user_id=#{publisher_user_id}&udid=#{udid}&source=#{source}&offer_id=#{id}&app_version=#{app_version}&viewed_at=#{viewed_at.to_f}&currency_id=#{currency_id}&country_code=#{country_code}"
    click_url += "&displayer_app_id=#{displayer_app_id}" if displayer_app_id.present?
    click_url += "&exp=#{exp}" if exp.present?
    click_url
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
  
  def get_icon_url(protocol = 'https://', base64 = false)
    if base64
      url = "#{API_URL}/get_app_image/icon?app_id=#{icon_id}"
    else
      url = "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy/icons/#{icon_id}.png"
    end
    url
  end
  
  def get_large_icon_url(protocol = 'https://')
    "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy/icons/large/#{icon_id}.png"
  end
  
  def get_medium_icon_url(protocol = 'https://')
    "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}tapjoy/icons/medium/#{icon_id}.jpg"
  end
  
  def get_cloudfront_icon_url
    "#{CLOUDFRONT_URL}/icons/#{icon_id}.png"
  end
  
  def get_large_cloudfront_icon_url
    "#{CLOUDFRONT_URL}/icons/large/#{icon_id}.png"
  end
  
  def get_medium_cloudfront_icon_url
    "#{CLOUDFRONT_URL}/icons/medium/#{icon_id}.jpg"
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
    self.rank_boost ||= rank_boosts.active.sum(:amount)
    self.rank_score = weights.keys.inject(0) { |sum, key| sum + (weights[key] * send("normal_#{key}")) }
    self.rank_score += rand * random_weight
    self.rank_score += rank_boost * boost_weight
    self.rank_score += over_threshold_weight if bid >= 40
    self.rank_score += 5 if item_type == "ActionOffer"
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
  
  def search_result_name
    search_name = name_with_suffix
    search_name += " (active)" if accepting_clicks?
    search_name += " (hidden)" if hidden?
    search_name
  end
  
  def should_reject?(publisher_app, device, currency, device_type, geoip_data, app_version, direct_pay_providers)
    return is_disabled?(publisher_app, currency) ||
        platform_mismatch?(publisher_app, device_type) ||
        geoip_reject?(geoip_data, device) ||
        age_rating_reject?(currency) ||
        already_complete?(publisher_app, device, app_version) ||
        show_rate_reject?(device) ||
        flixter_reject?(publisher_app, device) ||
        whitelist_reject?(publisher_app) ||
        gamevil_reject?(publisher_app) ||
        minimum_featured_bid_reject?(currency) ||
        jailbroken_reject?(device) ||
        direct_pay_reject?(direct_pay_providers) ||
        action_app_reject?(device)
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
    !self_promote_only? && (bid_is_bad? || bid_is_passable?)
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
    item_type == 'ActionOffer' ? third_party_data : item_id
  end
  
  def expensive?
    price > 299
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
    
    return device.has_app(app_id_for_device)
  end
  
  def show_rate_reject?(device)
    return false if EXEMPT_UDIDS.include?(device.key)
    
    srand( (device.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    return rand > show_rate
  end
  
  # TO REMOVE
  def gamevil_reject?(publisher_app)
    return publisher_app.partner_id == 'cea789f9-7741-4197-9cc0-c6ac40a0801a' && partner_id != 'cea789f9-7741-4197-9cc0-c6ac40a0801a'
  end
  # END TO REMOVE
  
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
  
  def whitelist_reject?(publisher_app)
    return !publisher_app_whitelist.blank? && !get_publisher_app_whitelist.include?(publisher_app.id)
  end
  
  def minimum_featured_bid_reject?(currency)
    return false unless (featured? && currency.minimum_featured_bid)
    bid < currency.minimum_featured_bid
  end
  
  def jailbroken_reject?(device)
    is_paid? && device.is_jailbroken?
  end
  
  def direct_pay_reject?(direct_pay_providers)
    return direct_pay? && !direct_pay_providers.include?(direct_pay)
  end
  
  def action_app_reject?(device)
    item_type == "ActionOffer" && !device.has_app(third_party_data)
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
    self.next_stats_aggregation_time = Time.zone.now if next_stats_aggregation_time.blank?
    self.stats_aggregation_interval = 3600 if stats_aggregation_interval.blank?
  end
  
  def recalculate_estimated_percentile
    weights = DEFAULT_WEIGHTS
    if conversion_rate == 0
      self.conversion_rate = is_paid? ? (0.05 / price) : 0.50
    end
    
    if featured?
      @stats ||= Offer.get_offer_rank_statistics(FEATURED_OFFER_TYPE)
      normalize_stats(@stats)
      calculate_rank_score(weights.merge({ :random => 0 }))
      @ranked_offers ||= Offer.get_cached_offers({ :type => FEATURED_OFFER_TYPE }).reject { |offer| offer.id == self.id }
      worse_offers = @ranked_offers.select { |offer| offer.rank_score < rank_score }
      100 * worse_offers.size / @ranked_offers.size
    else
      @stats ||= Offer.get_offer_rank_statistics(DEFAULT_OFFER_TYPE)
      normalize_stats(@stats)
      calculate_rank_score(weights.merge({ :random => 0 }))
      self.rank_score += weights[:random] * 0.5
      @ranked_offers ||= Offer.get_cached_offers({ :type => DEFAULT_OFFER_TYPE }).reject { |offer| offer.id == self.id }
      worse_offers = @ranked_offers.select { |offer| offer.rank_score < rank_score }
      100 * worse_offers.size / @ranked_offers.size
    end
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

  def check_enable_request
    if tapjoy_enabled?
      enable_offer_requests.each do |request|
        if request.status != STATUS_REJECTED && request.status != STATUS_APPROVED
          request.assigned_to = current_user
          request.approve!
        end
      end
    end
  end
end
