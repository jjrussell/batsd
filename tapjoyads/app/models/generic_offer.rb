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
#

class GenericOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_trackable :instructions => :instructions, :url => :url, :third_party_data => :third_party_data

  CATEGORIES = [ 'CPA', 'Social', 'Non-Native Video', 'Other' ]
  
  TRIGGER_ACTIONS = [ 'Facebook Login' ]

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner

  validates_presence_of :partner, :name, :url, :category
  validates_inclusion_of :category, :in => CATEGORIES, :allow_blank => true

  after_create :create_primary_offer
  after_update :update_offers

  scope :visible, :conditions => { :hidden => false }

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
      offer.instructions = instructions if instructions_changed? && !offer.instructions_overridden?
      offer.third_party_data = third_party_data if third_party_data_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end

end
