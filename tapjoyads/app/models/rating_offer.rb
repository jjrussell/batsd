class RatingOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_one :offer, :as => :item
  
  belongs_to :partner
  belongs_to :app
  
  validates_presence_of :partner, :app, :name
  
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
    offer.url = "http://ws.tapjoyads.com/rate_app_offer?record_id=TAPJOY_PUBLISHER_USER_RECORD_ID&udid=TAPJOY_UDID&app_id=#{app.id}&app_version=TAPJOY_APP_VERSION"
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
