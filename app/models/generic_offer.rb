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
#  protocol_handler :string(255)
#

class GenericOffer < ActiveRecord::Base
  include ActiveModel::Validations
  include UuidPrimaryKey
  extend ActiveSupport::Memoizable
  acts_as_trackable :instructions => :instructions, :url => :url, :third_party_data => :third_party_data

  CATEGORIES = [ 'CPA', 'Social', 'Non-Native Video', 'Other' ]

  TRIGGER_ACTIONS = [ 'Facebook Login', 'Facebook Like', 'Protocol Handler' ]

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  validates_presence_of :partner, :name, :url, :category
  validates_presence_of :prerequisite_offer, :if => Proc.new { |generic_offer| generic_offer.prerequisite_offer_id? }
  validates_inclusion_of :category, :in => CATEGORIES, :allow_blank => true
  validates :x_partner_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates :x_partner_exclusion_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates_with OfferPrerequisitesValidator

  after_create :create_primary_offer
  after_update :update_offers

  accepts_nested_attributes_for :primary_offer
  attr_accessor :primary_offer_creation_attributes

  scope :visible, :conditions => { :hidden => false }

  json_set_field :exclusion_prerequisite_offer_ids

  def get_x_partner_prerequisites
    Set.new(x_partner_prerequisites.split(';'))
  end
  memoize :get_x_partner_prerequisites

  def get_x_partner_exclusion_prerequisites
    Set.new(x_partner_exclusion_prerequisites.split(';'))
  end
  memoize :get_x_partner_exclusion_prerequisites

  private

  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.attributes = self.primary_offer_creation_attributes if self.primary_offer_creation_attributes
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.price = price
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url = url
    offer.instructions = instructions
    offer.third_party_data = third_party_data
    offer.prerequisite_offer_id = prerequisite_offer_id
    offer.exclusion_prerequisite_offer_ids = exclusion_prerequisite_offer_ids
    offer.x_partner_prerequisites = x_partner_prerequisites
    offer.x_partner_exclusion_prerequisites = x_partner_exclusion_prerequisites
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
      offer.exclusion_prerequisite_offer_ids = exclusion_prerequisite_offer_ids if exclusion_prerequisite_offer_ids_changed?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end

end
