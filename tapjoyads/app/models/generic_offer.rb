# == Schema Information
#
# Table name: generic_offers
#
#  id               :string(36)      not null, primary key
#  partner_id       :string(36)      not null
#  name             :string(255)     not null
#  description      :text
#  price            :integer(4)      default(0)
#  url              :string(255)     not null
#  third_party_data :string(255)
#  hidden           :boolean(1)      default(FALSE), not null
#  created_at       :datetime
#  updated_at       :datetime
#  instructions     :text
#  category         :string(255)
#  trigger_action   :string(255)
#

class GenericOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_trackable :instructions => :instructions, :url => :url, :third_party_data => :third_party_data

  CATEGORIES = [ 'CPA', 'Social', 'Non-Native Video', 'Other' ]

  TRIGGER_ACTIONS = [ 'Facebook Login', 'Facebook Like' ]

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'
  belongs_to :negative_prerequisite_offer, :class_name => 'Offer'

  validates_presence_of :partner, :name, :url, :category
  validates_presence_of :prerequisite_offer, :if => Proc.new { |generic_offer| generic_offer.prerequisite_offer_id? }
  validates_presence_of :negative_prerequisite_offer, :if => Proc.new { |generic_offer| generic_offer.negative_prerequisite_offer_id? }
  validates_inclusion_of :category, :in => CATEGORIES, :allow_blank => true
  validate :prerequisite_not_equal_to_negative_prerequisite

  after_create :create_primary_offer
  after_update :update_offers

  scope :visible, :conditions => { :hidden => false }

  private

  def prerequisite_not_equal_to_negative_prerequisite
    errors.add(:prerequisite_offer_id, 'prerequisite offer can not be the same as negative prerequisite offer.') if self.prerequisite_offer_id.present? && self.prerequisite_offer_id == self.negative_prerequisite_offer_id
  end

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
    offer.prerequisite_offer_id = prerequisite_offer_id
    offer.negative_prerequisite_offer_id = negative_prerequisite_offer_id
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.price = price if price_changed?
      offer.url = url if url_changed? && !offer.url_overridden?
      offer.instructions = instructions if instructions_changed? && !offer.instructions_overridden?
      offer.third_party_data = third_party_data if third_party_data_changed?
      offer.prerequisite_offer_id = prerequisite_offer_id if prerequisite_offer_id_changed?
      offer.negative_prerequisite_offer_id = negative_prerequisite_offer_id if negative_prerequisite_offer_id_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end

end
