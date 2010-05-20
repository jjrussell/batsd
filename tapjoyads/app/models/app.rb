class App < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_one :offer, :as => :item
  has_many :publisher_conversions, :class_name => 'Conversion', :foreign_key => :publisher_app_id
  
  belongs_to :partner
  
  validates_presence_of :partner, :name
  validates_inclusion_of :use_raw_url, :in => [ true, false ]
  
  after_create :create_offer
  after_update :update_offer
  
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
  
private
  
  def create_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = price
    offer.url = store_url
    offer.device_types = platform == 'android' ? Offer::ANDROID_DEVICES.to_json : Offer::IPHONE_DEVICES.to_json
    offer.save!
  end
  
  def update_offer
    offer.name = name if name_changed?
    offer.description = description if description_changed?
    offer.price = price if price_changed?
    offer.url = store_url if store_url_changed? || use_raw_url_changed? || store_id_changed?
    offer.save! if offer.changed?
  end
  
end
