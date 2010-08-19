class RatingOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  belongs_to :app
  
  validates_presence_of :partner, :app, :name
  
  before_validation :set_name_and_description
  after_create :create_offer, :create_icon
  after_update :update_offer
  after_save :update_memcached
  before_destroy :clear_memcached
  
  def self.find_in_cache_by_app_id(app_id)
    Mc.get_and_put("mysql.rating_offer.#{app_id}") { RatingOffer.find_by_app_id(app_id) }
  end
  
  def get_id_for_device_app_list(app_version)
    RatingOffer.get_id_for_device_app_list(id, app_version)
  end
  
  def self.get_id_for_device_app_list(id, app_version)
    app_version.blank? ? id : (id + '.' + app_version)
  end
  
private
  
  def set_name_and_description
    self.name = "Rate #{app.name} in the App Store"
    self.description = "Go to the App Store where you can quickly submit a rating for #{app.name}. This is on the honor system."
  end
  
  def create_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = 0
    offer.url = "http://ws.tapjoyads.com/rate_app_offer?udid=TAPJOY_UDID&app_id=#{app.id}"
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.instructions = "Go to the App Store where you can rate this app."
    offer.credit_card_required = false
    offer.time_delay = 'in seconds'
    offer.payment = 15
    offer.ordinal = 1
    offer.third_party_data = app_id
    offer.tapjoy_enabled = false
    offer.user_enabled = true
    offer.save!
  end
  
  def update_offer
    offer.partner_id = partner_id if partner_id_changed?
    offer.name = name if name_changed?
    offer.description = description if description_changed?
    offer.save! if offer.changed?
  end
  
  def update_memcached
    Mc.put("mysql.rating_offer.#{app_id}", self)
  end
  
  def clear_memcached
    Mc.delete("mysql.rating_offer.#{app_id}")
  end
  
  def create_icon
    retries = 3
    begin
      bucket = S3.bucket(BucketNames::APP_DATA)
      image_data = bucket.get('icons/ratestar.png')
      bucket.put("icons/#{id}.png", image_data, {}, 'public-read')
    rescue
      sleep 0.5
      retries -= 1
      retry if retries > 0
    end
  end
  
end
