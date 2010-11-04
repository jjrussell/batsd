class App < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord
  
  PLATFORMS = { 'android' => 'Android', 'iphone' => 'iOS' }
  TRADEDOUBLER_COUNTRIES = Set.new(%w( GB FR DE IT IE ES NL AT CH BE DK FI NO SE LU PT GR ))
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_app_id
  has_one :currency
  has_one :rating_offer
  
  belongs_to :partner
  
  validates_presence_of :partner, :name
  validates_inclusion_of :platform, :in => PLATFORMS.keys

  after_create :create_primary_offer
  after_update :update_offers
  after_update :update_rating_offer
  
  named_scope :visible, :conditions => { :hidden => false }

  def is_android?
    platform == 'android'
  end
  
  def platform_name
    PLATFORMS[platform]
  end
  
  def store_name
    is_android? ? 'Marketplace' : 'App Store'
  end

  def virtual_goods
    VirtualGood.select(:where => "app_id = '#{self.id}'")[:items]
  end

  def store_url
    if use_raw_url?
      read_attribute(:store_url)
    else
      if is_android?
        "market://search?q=#{store_id}"
      else
        "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
      end
    end
  end
  
  def store_url=(url)
    if use_raw_url?
      write_attribute(:store_url, url)
    end
  end
  
  def final_store_url
    if is_android?
      "http://www.cyrket.com/p/android/#{store_id}"
    else
      "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
    end
  end

  def primary_country
    countries = primary_offer.present? && self.primary_offer.countries
    if countries.present? && !JSON.parse(countries).include?("US")
      JSON.parse(countries).first
    else
      "us"
    end
  end

  ##
  # Grab data from the app store and mutate self with data.
  def fill_app_store_data(country=nil)
    return if store_id.blank?
    data = AppStore.fetch_app_by_id(store_id, platform, country)
    if (data.nil?) # might not be available in the US market
      data = AppStore.fetch_app_by_id(store_id, platform, primary_country)
    end
    self.name = data[:title]
    self.price = (data[:price] * 100).ceil
    self.description = data[:description]
    self.age_rating = data[:age_rating]
    download_icon(data[:icon_url], data[:large_icon_url])
  end

  def download_icon(url, large_url)
    return if url.blank?
    set_primary_key if id.nil?
    begin
      icon = Downloader.get(url, :timeout => 30)
      large_icon = Downloader.get(large_url, :timeout => 30)
      medium_icon = Magick::Image.from_blob(large_icon)[0].resize(256, 256).to_blob{|i| i.format = 'JPG'}
      
      bucket = S3.bucket(BucketNames::APP_DATA)
      bucket.put("icons/#{id}.png", icon, {}, "public-read")
      bucket.put("icons/large/#{id}.png", large_icon, {}, "public-read")
      bucket.put("icons/medium/#{id}.jpg", medium_icon, {}, "public-read")
      
      Mc.delete("icon.s3.#{id}")
    rescue
      Rails.logger.info "Failed to download icon for url: #{url}"
      Notifier.alert_new_relic(AppDataFetchError, "icon url #{url} for app id #{id}")
    end
  end

  def get_icon_url(protocol='http://')
    "#{protocol}s3.amazonaws.com/#{RUN_MODE_PREFIX}app_data/icons/#{id}.png"
  end

  def get_offer_list(udid, options = {})
    currency = options.delete(:currency)
    device_type = options.delete(:device_type)
    geoip_data = options.delete(:geoip_data) { {} }
    type = options.delete(:type) { Offer::DEFAULT_OFFER_TYPE }
    required_length = options.delete(:required_length) { 999 }
    app_version = options.delete(:app_version)
    reject_rating_offer = options.delete(:reject_rating_offer) { false }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    device = Device.new(:key => udid)
    currency = Currency.find_in_cache(id) unless currency
    
    if type == Offer::CLASSIC_OFFER_TYPE
      offer_list = []
    elsif type == Offer::FEATURED_OFFER_TYPE
      offer_list = Offer.get_featured_offers
    else
      exp = Experiments.choose(udid)
      offer_list = Offer.get_enabled_offers(exp)
    end
    
    final_offer_list = []
    num_rejected = 0
    offer_list.each do |o|
      if o.should_reject?(self, device, currency, device_type, geoip_data, app_version, reject_rating_offer)
        num_rejected += 1
      else
        final_offer_list << o
      end
      break if required_length == final_offer_list.length
    end
    
    [ final_offer_list, offer_list.length - final_offer_list.length - num_rejected ]
  end
  
  def parse_store_id_from_url(url, alert_on_parse_fail = true)
    if use_raw_url?
      return store_id
    end
    
    if url.blank? || url == 'None'
      Notifier.alert_new_relic(ParseStoreIdError, "Could not parse store id from nil url for app #{name} (#{id})") if alert_on_parse_fail
      return nil
    end
    
    if is_android?
      return url
    end
    
    match = url.match(/\/id(\d*)\?/)
    unless match
      match = url.match(/[&|?]id=(\d*)/)
    end
    
    unless match && match[1]
      Notifier.alert_new_relic(ParseStoreIdError, "Could not parse store id from #{url} for app #{name} (#{id})") if alert_on_parse_fail
      return nil
    end
    
    return match[1]
  end

  def display_money_share
    0.4
  end

private
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = price
    offer.min_payment = offer.is_paid? ? (price.to_f / 2).ceil : 35
    offer.payment = offer.min_payment
    offer.url = store_url
    offer.device_types = is_android? ? Offer::ANDROID_DEVICES.to_json : Offer::APPLE_DEVICES.to_json
    offer.instructions = 'Install and then run the app while online to receive credit.'
    offer.time_delay = 'in seconds'
    offer.credit_card_required = false
    offer.third_party_data = store_id
    offer.age_rating = age_rating
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.description = description if description_changed?
      if price_changed?
        offer.price = price
        offer.min_payment = offer.is_paid? ? (price.to_f / 2).ceil : 35
        offer.payment = offer.min_payment if offer.payment < offer.min_payment
      end
      offer.url = store_url if store_url_changed? || use_raw_url_changed? || store_id_changed?
      offer.third_party_data = store_id if store_id_changed?
      offer.age_rating = age_rating if age_rating_changed?
      offer.hidden = hidden if hidden_changed?
      offer.tapjoy_enabled = false if hidden? && hidden_changed?
      offer.save! if offer.changed?
    end
  end
  
  def update_rating_offer
    if store_id_changed? && rating_offer.present?
      rating_offer.offers.each do |offer|
        offer.url = store_url
        offer.save!
      end
    end
  end
  
end
