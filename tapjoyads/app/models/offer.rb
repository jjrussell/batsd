class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  
  APPLE_DEVICES = %w( iphone itouch ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES
  EXEMPT_UDID = 'c73e730913822be833766efffc7bb1cf239d855a'
  
  CLASSIC_OFFER_TYPE  = '0'
  DEFAULT_OFFER_TYPE  = '1'
  FEATURED_OFFER_TYPE = '2'
  
  NUM_MEMCACHE_KEYS = 30
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url, :instructions, :time_delay
  validates_numericality_of :price, :ordinal, :only_integer => true
  validates_numericality_of :payment, :only_integer => true, :if => Proc.new { |offer| offer.tapjoy_enabled? && offer.user_enabled? }
  validates_numericality_of :actual_payment, :only_integer => true, :allow_nil => true
  validates_numericality_of :conversion_rate, :greater_than_or_equal_to => 0
  validates_numericality_of :show_rate, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :credit_card_required, :self_promote_only, :featured, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer OfferpalOffer RatingOffer )
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
  
  before_save :cleanup_url
  after_save :update_memcached
  before_destroy :clear_memcached
  
  named_scope :enabled_offers, { :joins => :partner, :conditions => "payment > 0 AND tapjoy_enabled = true AND user_enabled = true AND ((partners.balance > 0 AND item_type IN ('App', 'EmailOffer')) OR item_type = 'RatingOffer')", :order => "ordinal ASC" }
  named_scope :classic_offers, { :conditions => "tapjoy_enabled = true AND user_enabled = true AND item_type = 'OfferpalOffer'", :order => "ordinal ASC" }
  named_scope :featured, { :conditions => "featured = true" }
  named_scope :nonfeatured, { :conditions => "featured = false" }
  named_scope :to_aggregate_stats, lambda { { :conditions => ["next_stats_aggregation_time < ?", Time.zone.now], :order => "next_stats_aggregation_time ASC" } }
  
  def self.get_enabled_offers
    Mc.get_and_put("s3.enabled_offers_#{rand(NUM_MEMCACHE_KEYS) * 123123}") do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.get('enabled_offers'))
    end
  end
  
  def self.get_classic_offers
    Mc.get_and_put('s3.classic_offers') do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.get('classic_offers'))
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
    offer_list = Offer.enabled_offers.nonfeatured
    
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
    
    bucket.put('enabled_offers', Marshal.dump(offer_list))
    NUM_MEMCACHE_KEYS.times do |i|
      Mc.put("s3.enabled_offers_#{i * 123123}", offer_list)
    end
  end
  
  def self.cache_classic_offers
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    offer_list = Offer.classic_offers
    bucket.put('classic_offers', Marshal.dump(offer_list))
    Mc.put('s3.classic_offers', offer_list)
  end
  
  def self.cache_featured_offers
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    offer_list = Offer.enabled_offers.featured
    bucket.put('featured_offers', Marshal.dump(offer_list))
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
  
  def get_destination_url(udid, publisher_app_id, publisher_user_id = nil, app_version = nil)
    int_record_id = publisher_user_id.nil? ? '' : PublisherUserRecord.generate_int_record_id(publisher_app_id, publisher_user_id)
    
    final_url = url.gsub('TAPJOY_UDID', udid.to_s)
    if item_type == 'RatingOffer'
      final_url += "&publisher_user_id=#{publisher_user_id}&app_version=#{app_version}"
    elsif item_type == 'OfferpalOffer'
      final_url.gsub!('TAPJOY_GENERIC', int_record_id.to_s)
    elsif item_type == 'EmailOffer'
      final_url += "&publisher_app_id=#{publisher_app_id}"
    end
    
    final_url
  end
  
  def get_click_url(publisher_app, publisher_user_id, udid, source)
    "http://ws.tapjoyads.com/submit_click/store?advertiser_app_id=#{item_id}&publisher_app_id=#{publisher_app.id}&publisher_user_id=#{publisher_user_id}&udid=#{udid}&source=#{source}&offer_id=#{id}"
  end
  
  def get_redirect_url(publisher_app, publisher_user_id, udid, source, app_version)
    if item_type == 'RatingOffer'
      return get_destination_url(udid, publisher_app.id, publisher_user_id, app_version)
    end
    get_click_url(publisher_app, publisher_user_id, udid, source) + "&redirect=1"
  end
  
  def get_icon_url(base64 = false)
    if base64
      url = "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{item_id}"
    else
      url = "http://s3.amazonaws.com/#{RUN_MODE_PREFIX}app_data/icons/#{item_id}.png"
    end
    url
  end
  
  def get_email_url(publisher_user_id, publisher_app, udid, app_version)
    "http://www.tapjoyconnect.com/complete_offer" +
        "?offerid=#{CGI::escape(id)}" +
        "&udid=#{udid}" +
        "&publisher_user_id=#{publisher_user_id}" +
        "&app_id=#{publisher_app.id}" +
        "&url=#{CGI::escape(CGI::escape(get_destination_url(udid, publisher_app.id, publisher_user_id, app_version)))}"
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
  
  def name_with_suffix
    name_suffix.blank? ? name : "#{name} -- #{name_suffix}"
  end
  
  def should_reject?(publisher_app, device_app_list, currency, device_type, geoip_data, app_version, reject_rating_offer, show_secondary_offers)
    return is_disabled?(publisher_app, currency) ||
        platform_mismatch?(publisher_app, device_type) ||
        geoip_reject?(geoip_data, device_app_list) ||
        age_rating_reject?(currency) ||
        rating_offer_reject?(publisher_app, reject_rating_offer) ||
        already_complete?(publisher_app, device_app_list, app_version) ||
        show_rate_reject?(device_app_list) ||
        flixter_reject?(publisher_app, device_app_list) ||
        whitelist_reject?(publisher_app) ||
        secondary_offer_reject?(show_secondary_offers)
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
    return false if device_app_list.key == EXEMPT_UDID

    return true if !countries.blank? && countries != '[]' && !get_countries.include?(geoip_data[:country])
    return true if !postal_codes.blank? && postal_codes != '[]' && !get_postal_codes.include?(geoip_data[:postal_code])
    return true if !cities.blank? && cities != '[]' && !get_cities.include?(geoip_data[:city])
        
    return false
  end
  
  def already_complete?(publisher_app, device_app_list, app_version)
    return false if device_app_list.key == EXEMPT_UDID
    
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
    return false if device_app_list.key == EXEMPT_UDID
    
    srand( (device_app_list.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    return rand > show_rate
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
  
  ##
  # Reject all secondary offers if the request is coming from the old sdk.
  def secondary_offer_reject?(show_secondary_offers)
    return is_secondary? && !show_secondary_offers
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
  
end
