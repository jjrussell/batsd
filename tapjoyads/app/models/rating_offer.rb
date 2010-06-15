class RatingOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_one :offer, :as => :item
  
  belongs_to :partner
  belongs_to :app
  
  validates_presence_of :partner, :app, :name
  
  before_validation :set_name_and_description
  after_create :create_offer
  after_update :update_offer
  
private
  
  def set_name_and_description
    self.name = "Rate #{app.name} in the App Store"
    self.description = "You must Open in Safari.  Clicking Complete Offer will not work.  Click Open in Safari to go to the App Store where you can quickly submit a rating for #{app.name}.  This is on the honor system."
  end
  
  def create_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = 0
    offer.url = "http://ws.tapjoyads.com/rate_app_offer?record_id=TAPJOY_PUBLISHER_USER_RECORD_ID&udid=TAPJOY_UDID&app_id=#{app.id}&app_version=TAPJOY_APP_VERSION"
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.instructions = "Just click the Open in Safari button to go to the App Store where you can rate this app."
    offer.credit_card_required = false
    offer.time_delay = 'in seconds'
    offer.payment = 15
    offer.ordinal = 1
    offer.save!
  end
  
  def update_offer
    offer.partner_id = partner_id if partner_id_changed?
    offer.name = name if name_changed?
    offer.description = description if description_changed?
    offer.save! if offer.changed?
  end
  
end
