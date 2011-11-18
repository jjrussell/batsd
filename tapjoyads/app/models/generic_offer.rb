class GenericOffer < ActiveRecord::Base
  include UuidPrimaryKey

  CATEGORIES = [ 'CPA', 'Social', 'Video' ]

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner

  validates_presence_of :partner, :name, :url
  validates_inclusion_of :category, :in => CATEGORIES, :allow_blank => true

  after_create :create_primary_offer
  after_update :update_offers

  named_scope :visible, :conditions => { :hidden => false }

private

  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.price = price
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url = url
    offer.instructions = instructions
    offer.third_party_data = third_party_data
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.price = price if price_changed?
      offer.url = url if url_changed? && !offer.url_overridden?
      offer.instructions = instructions if instructions_changed?
      offer.third_party_data = third_party_data if third_party_data_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end

end
