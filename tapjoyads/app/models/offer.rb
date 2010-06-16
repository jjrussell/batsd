class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedHelper
  
  APPLE_DEVICES = %w( iphone itouch ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES
  EXEMPT_UDID = '298c5159a3681207eaba5a04b3573aa7b4f13d99'
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url, :instructions, :time_delay
  validates_numericality_of :price, :ordinal, :only_integer => true
  validates_numericality_of :payment, :only_integer => true, :if => Proc.new { |offer| offer.tapjoy_enabled? && offer.user_enabled? }
  validates_numericality_of :actual_payment, :only_integer => true, :allow_nil => true
  validates_numericality_of :conversion_rate, :show_rate, :greater_than_or_equal_to => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :credit_card_required, :self_promote_only, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer OfferpalOffer RatingOffer )
  
  named_scope :enabled_offers, { :joins => :partner, :conditions => "payment > 0 AND tapjoy_enabled = true AND user_enabled = true AND partners.balance > 0", :order => "ordinal ASC" }
  named_scope :classic_offers, { :conditions => "item_type IN ('OfferpalOffer', 'RatingOffer')", :order => "ordinal ASC" }
  
  def self.get_enabled_offers
    Offer.new.get_from_cache_and_save('s3.enabled_offers') do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      Marshal.restore(bucket.get('enabled_offers'))
    end
  end
  
  def self.get_classic_offers
    Offer.new.get_from_cache_and_save('s3.classic_offers') do
      bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
      Marshal.restore(bucket.get('classic_offers'))
    end
  end
  
  def self.cache_enabled_offers
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    offer_list = Offer.enabled_offers
    
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
    Offer.new.save_to_cache('s3.enabled_offers', offer_list)
  end
  
  def self.cache_classic_offers
    bucket = RightAws::S3.new.bucket(RUN_MODE_PREFIX + 'offer-data')
    offer_list = Offer.classic_offers
    bucket.put('classic_offers', Marshal.dump(offer_list))
    Offer.new.save_to_cache('s3.classic_offers', offer_list)
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
  
  def get_destination_url(udid, publisher_app_id = '')
    url.gsub('TAPJOY_UDID', udid).gsub('TAPJOY_PUBLISHER_APP_ID', publisher_app_id)
  end
  
  def get_click_url(publisher_app, publisher_user_record, udid)
    "http://ws.tapjoyads.com/submit_click/store?advertiser_app_id=#{id}&publisher_app_id=#{publisher_app.id}&publisher_user_record_id=#{publisher_user_record.get_record_id}&udid=#{udid}"
  end
  
  def get_redirect_url(publisher_app, publisher_user_record, udid)
    get_click_url(publisher_app, publisher_user_record, udid) + "&redirect=1"
  end

  def get_offerpal_destination_url(publisher_user_record, udid = nil, app_version = nil)
    url.gsub('TAPJOY_GENERIC', publisher_user_record.get_int_record_id).
        gsub('TAPJOY_PUBLISHER_USER_RECORD_ID', publisher_user_record.get_int_record_id).
        gsub('TAPJOY_UDID', udid.to_s).
        gsub('TAPJOY_APP_VERSION', app_version.to_s)
  end
  
  def get_icon_url(base64 = false)
    if base64
      url = "http://ws.tapjoyads.com/get_app_image/icon?app_id=#{id}"
    else
      url = "https://s3.amazonaws.com/app_data/icons/#{id}.png"
    end
    url
  end
  
  def get_email_url(publisher_user_record, publisher_app, udid)
    "http://www.tapjoyconnect.com/complete_offer" +
        "?offerid=#{CGI::escape(id)}" +
        "&udid=#{udid}" +
        "&record_id=#{publisher_user_record.get_record_id}" +
        "&app_id=#{publisher_app.id}" +
        "&url=#{CGI::escape(CGI::escape(get_offerpal_destination_url(publisher_user_record)))}"
  end
  
  def get_countries
    Set.new(JSON.parse(countries))
  end
  
  def get_postal_codes
    Set.new(JSON.parse(postal_codes))
  end
  
  def get_cities
    Set.new(JSON.parse(cities))
  end
  
  def get_device_types
    Set.new(JSON.parse(device_types))
  end
  
  def adjust_cvr_for_ranking
    boost = 0
    if id == '875d39dd-8227-49a2-8af4-cbd5cb583f0e'
      # MyTown: boost cvr by 20-30%
      boost = 0.2 + rand * 0.1
    elsif id == 'f8751513-67f1-4273-8e4e-73b1e685e83d'
      # Movies: boost cvr by 35-40%
      boost = 0.35 + rand * 0.05
    elsif id == '547f141c-fdf7-4953-9895-83f2545a48b4'
      # CauseWorld: US-only, so it has a low cvr. Boost it by 30-40%
      boost = 0.3 + rand * 0.1
    elsif partner_id == '70f54c6d-f078-426c-8113-d6e43ac06c6d' && is_free?
      # Tapjoy apps: reduce cvr by 5%
      boost = -0.05
    elsif is_paid?
      # Boost all paid apps by 0-15%, causing churn.
      boost = rand * 0.15
    end
    
    self.conversion_rate = pay_per_click? ? (0.75 + rand * 0.15) : (conversion_rate + boost)
  end

  def should_reject?(publisher_app, device_app_list, currency, device_type, geoip_data)
    return is_disabled?(publisher_app, currency) ||
        platform_mismatch?(publisher_app, device_type) ||
        geoip_reject?(geoip_data, device_app_list) ||
        age_rating_reject?(currency) ||
        already_complete?(device_app_list) ||
        show_rate_reject?(device_app_list) ||
        flixter_reject?(publisher_app, device_app_list)
  end

private
  
  def is_disabled?(publisher_app, currency)
    return id == currency.app_id || 
        currency.get_disabled_offer_ids.include?(id) || 
        currency.get_disabled_partner_ids.include?(partner_id) ||
        (currency.only_free_offers? && is_paid?) ||
        (self_promote_only? && partner_id != publisher_app.partner_id)
  end
  
  def platform_mismatch?(publisher_app, device_type_param)
    device_type = normalize_device_type(device_type_param)
    device_type = publisher_app.platform if device_type.nil?
    
    return !get_device_types.include?(device_type)
  end
  
  def age_rating_reject?(currency)
    return false if currency.max_age_rating.nil?
    return false if age_rating.nil?
    return currency.max_age_rating < age_rating
  end
  
  def geoip_reject?(geoip_data, device_app_list)
    return false if device_app_list.key == EXEMPT_UDID

    return true if !countries.nil? && countries != '[]' && !get_countries.include?(geoip_data[:country])
    return true if !postal_codes.nil? && postal_codes != '[]' && !get_postal_codes.include?(geoip_data[:postal_code])
    return true if !cities.nil? && cities != '[]' && !get_cities.include?(geoip_data[:city])
        
    return false
  end
  
  def already_complete?(device_app_list)
    return false if device_app_list.key == EXEMPT_UDID
    
    return device_app_list.has_app(id)
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

end
