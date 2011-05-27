class RatingOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  belongs_to :app
  
  validates_presence_of :partner, :app, :name
  
  before_validation :set_name_and_description
  after_create :create_primary_offer, :create_icon
  after_update :update_offers

  delegate :is_android?, :to => :app

  named_scope :visible, :conditions => { :hidden => false }
  
  def get_id_with_app_version(app_version)
    RatingOffer.get_id_with_app_version(id, app_version)
  end
  
  def self.get_id_with_app_version(id, app_version)
    app_version.blank? ? id : (id + '.' + app_version)
  end
  
private
  
  def set_name_and_description
    self.name = "Rate #{app.name} in the App Store"
    self.description = "Go to the App Store where you can quickly submit a rating for #{app.name}. This is on the honor system."
  end
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.price = 0
    offer.url = app.store_url
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.bid = 0
    offer.reward_value = 15
    offer.third_party_data = app_id
    offer.tapjoy_enabled = false
    offer.user_enabled = true
    offer.pay_per_click = true
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.hidden = hidden if hidden_changed?
      offer.url = app.store_url
      offer.save! if offer.changed?
    end
  end
  
  def create_icon
    retries = 3
    begin
      bucket = S3.bucket(BucketNames::TAPJOY)
      image_data = bucket.get('icons/ratestar.png')
      bucket.put("icons/#{id}.png", image_data, {}, 'public-read')
      
      image_data = bucket.get('icons/114/ratestar.jpg')
      primary_offer.save_icon!(image_data)
    rescue
      sleep 0.5
      retries -= 1
      retry if retries > 0
    end
  end
  
end
