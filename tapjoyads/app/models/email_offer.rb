class EmailOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_one :offer, :as => :item
  
  belongs_to :partner
  
  validates_presence_of :partner, :name
  
  after_create :create_offer
  after_update :update_offer
  
private
  
  def create_offer
    self.offer = Offer.new(:item => self)
    self.offer.id = id
    self.offer.partner = partner
    self.offer.name = name
    self.offer.description = description
    self.offer.price = 0
    self.offer.url = "http://ws.tapjoyads.com/list_signup?udid=TAPJOY_UDID&publisher_app_id=TAPJOY_PUBLISHER_APP_ID&advertiser_app_id=#{id}"
    self.offer.device_types = Offer::ALL_DEVICES.to_json
    self.offer.save!
  end
  
  def update_offer
    self.offer.name = name if name_changed?
    self.offer.description = description if description_changed?
    self.offer.save! if self.offer.changed?
  end
  
end
