class App < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedHelper
  
  has_one :offer, :as => :item
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_app_id
  has_one :currency
  has_one :rating_offer
  
  belongs_to :partner
  
  validates_presence_of :partner, :name
  validates_inclusion_of :use_raw_url, :in => [ true, false ]
  
  after_create :create_offer
  after_update :update_offer
  after_save :update_memcached
  
  def self.find_in_cache(id)
    App.new.get_from_cache_and_save("mysql.app.#{id}") { App.find(id) }
  end
  
  def store_url
    if use_raw_url?
      read_attribute(:store_url)
    else
      if platform == 'android'
        "http://market.android.com/details?id=#{store_id}"
      else
        web_object_url = "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
        "http://click.linksynergy.com/fs-bin/click?id=OxXMC6MRBt4&subid=&offerid=146261.1&type=10&tmpid=3909&RD_PARM1=#{CGI::escape(web_object_url)}"
      end
    end
  end
  
  def store_url=(url)
    if use_raw_url?
      write_attribute(:store_url, url)
    end
  end
  
  def get_offer_list(udid, options = {})
    currency = options.delete(:currency)
    device_type = options.delete(:device_type)
    geoip_data = options.delete(:geoip_data)
    type = options.delete(:type) { '1' }
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?
    
    device_app_list = DeviceAppList.new(:key => udid)
    currency = Currency.find_in_cache(id) unless currency
    
    if type == '0'
      offer_list = Offer.get_classic_offers
    else
      offer_list = Offer.get_enabled_offers
      rate_offer = RatingOffer.find_in_cache(id)
      offer_list.unshift(rate_offer) unless rate_offer.nil?
    end
    
    offer_list.reject! do |o|
      o.should_reject?(self, device_app_list, currency, device_type, geoip_data)
    end
    
    offer_list
  end
  
private
  
  def create_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = price
    offer.url = store_url
    offer.device_types = platform == 'android' ? Offer::ANDROID_DEVICES.to_json : Offer::APPLE_DEVICES.to_json
    offer.instructions = 'Install and then run the app while online to receive credit.'
    offer.time_delay = 'in seconds'
    offer.credit_card_required = false
    offer.third_party_data = store_id
    offer.age_rating = age_rating
    offer.save!
  end
  
  def update_offer
    offer.partner_id = partner_id if partner_id_changed?
    offer.name = name if name_changed?
    offer.description = description if description_changed?
    offer.price = price if price_changed?
    offer.url = store_url if store_url_changed? || use_raw_url_changed? || store_id_changed?
    offer.third_party_data = store_id if store_id_changed?
    offer.age_rating = age_rating if age_rating_changed?
    offer.save! if offer.changed?
  end
  
  def update_memcached
    save_to_cache("mysql.app.#{id}", self)
  end
  
end
