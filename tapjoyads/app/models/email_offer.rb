class EmailOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_one :offer, :as => :item
  
  belongs_to :partner
  
  validates_presence_of :partner, :name
  
  after_create :create_offer
  after_update :update_offer
  
private
  
  def create_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = 0
    offer.url = "http://ws.tapjoyads.com/list_signup?udid=TAPJOY_UDID&publisher_app_id=TAPJOY_PUBLISHER_APP_ID&advertiser_app_id=#{id}"
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.save!
  end
  
  def update_offer
    offer.partner_id = partner_id if partner_id_changed?
    offer.name = name if name_changed?
    offer.description = description if description_changed?
    offer.save! if offer.changed?
  end
  
end
