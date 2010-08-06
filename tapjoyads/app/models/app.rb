class App < ActiveRecord::Base
  include UuidPrimaryKey
  
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
  before_destroy :clear_memcached
  
  def self.find_in_cache(id, do_lookup = true)
    if do_lookup
      Mc.get_and_put("mysql.app.#{id}") { App.find(id) }
    else
      Mc.get("mysql.app.#{id}")
    end
  end
  
  def store_url
    if use_raw_url?
      read_attribute(:store_url)
    else
      if platform == 'android'
        "market://search?q=#{store_id}"
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
  
  def final_store_url
    if platform == 'android'
      "http://www.cyrket.com/p/android/#{store_id}"
    else
      "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
    end
  end
  
  ##
  # Returns the value that the url should be set to on mssql.
  def mssql_store_url
    if use_raw_url?
      read_attribute(:store_url)
    else
      if platform == 'android'
        store_id
      else
        "http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=#{store_id}&mt=8"
      end
    end
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
    
    device_app_list = DeviceAppList.new(:key => udid)
    currency = Currency.find_in_cache_by_app_id(id) unless currency
    
    if type == Offer::CLASSIC_OFFER_TYPE
      offer_list = Offer.get_classic_offers
    elsif type == Offer::FEATURED_OFFER_TYPE
      offer_list = Offer.get_featured_offers
    else
      offer_list = Offer.get_enabled_offers
    end
    
    final_offer_list = []
    num_rejected = 0
    offer_list.each do |o|
      if o.should_reject?(self, device_app_list, currency, device_type, geoip_data, app_version, reject_rating_offer)
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
    
    if platform == 'android'
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

  def to_json_with_offer
    self.to_json(
      :include => {
        :offer => {
          :methods => [ :get_icon_url ]
        }
      },
      :methods => [ :store_url ]
    )
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
    Mc.put("mysql.app.#{id}", self)
  end
  
  def clear_memcached
    Mc.delete("mysql.app.#{id}")
  end
  
end
