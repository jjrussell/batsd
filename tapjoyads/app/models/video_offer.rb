class VideoOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  
  validates_presence_of :partner, :name, :video_url
  
  after_create :create_primary_offer
  after_update :update_offers
  
  named_scope :visible, :conditions => { :hidden => false }
  
private
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.price = 0
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.third_party_data = video_url
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.third_party_data = video_url if video_url_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end
  
end
