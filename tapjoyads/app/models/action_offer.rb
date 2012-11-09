# == Schema Information
#
# Table name: action_offers
#
#  id                    :string(36)      not null, primary key
#  partner_id            :string(36)      not null
#  app_id                :string(36)      not null
#  name                  :string(255)     not null
#  instructions          :text
#  hidden                :boolean(1)      default(FALSE), not null
#  created_at            :datetime
#  updated_at            :datetime
#  variable_name         :string(255)     not null
#  prerequisite_offer_id :string(36)
#  price                 :integer(4)      default(0)
#

class ActionOffer < ActiveRecord::Base
  include ActiveModel::Validations
  include UuidPrimaryKey
  extend ActiveSupport::Memoizable
  acts_as_trackable :device_types => lambda { |ctx| app.primary_offer.device_types }, :icon_id_override => :app_id, :instructions => :instructions, :url => lambda { |ctx| app.store_url }

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner
  belongs_to :app
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  validates_presence_of :partner, :app, :name, :variable_name
  validates_uniqueness_of :variable_name, :scope => :app_id, :case_sensitive => false
  validates_presence_of :instructions
  validates_presence_of :prerequisite_offer, :if => Proc.new { |action_offer| action_offer.prerequisite_offer_id? }
  validates :x_partner_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates :x_partner_exclusion_prerequisites, :id_list => {:of => Offer}, :allow_blank => true
  validates_numericality_of :price, :only_integer => true, :greater_than_or_equal_to => 0
  validates_with OfferPrerequisitesValidator

  scope :visible, :conditions => { :hidden => false }

  accepts_nested_attributes_for :primary_offer

  before_validation :set_variable_name
  after_create :create_primary_offer
  after_create :create_secondary_offers
  after_update :update_offers

  delegate :user_enabled?, :tapjoy_enabled?, :bid, :min_bid, :daily_budget, :integrated?, :to => :primary_offer
  delegate :get_offer_device_types, :store_id, :store_url, :wifi_required?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  json_set_field :exclusion_prerequisite_offer_ids

  def toggle_user_enabled
    primary_offer.toggle_user_enabled
    primary_offer.save
  end

  def create_offer_from_app_metadata(app_metadata)
    offer                  = build_offer
    offer.url              = app_metadata.store_url
    offer.device_types     = app_metadata.get_offer_device_types
    offer.price            = offer_price(app_metadata)
    offer.bid              = offer.min_bid
    offer.name_suffix      = "action (#{app_metadata.store.name})"
    offer.icon_id_override = app_metadata.id
    offer.app_metadata     = app_metadata
    offer.save!
  end

  def update_offers_for_app_metadata(old_app_metadata, new_app_metadata)
    offers.find_all_by_app_metadata_id(old_app_metadata.id).each do |offer|
      offer.name_suffix = "action (#{new_app_metadata.store_name})" if offer.name_suffix == "action (#{old_app_metadata.store_name})"
      offer.icon_id_override = new_app_metadata.id if offer.icon_id_override == old_app_metadata.id
      offer.update_from_app_metadata(new_app_metadata)
    end
  end

  def remove_offers_for_app_metadata(app_metadata)
    offers.find_all_by_app_metadata_id(app_metadata.id).each do |offer|
      offer.destroy
    end
  end

  def offer_price(app_metadata = nil)
    (prerequisite_offer_id? ? 0 : (app_metadata ? app_metadata.price : app.price)) + price
  end

  def get_x_partner_prerequisites
    Set.new(x_partner_prerequisites.split(';'))
  end
  memoize :get_x_partner_prerequisites

  def get_x_partner_exclusion_prerequisites
    Set.new(x_partner_exclusion_prerequisites.split(';'))
  end
  memoize :get_x_partner_exclusion_prerequisites

  private

  def build_offer
    offer                                   = Offer.new(:item => self)
    offer.partner                           = partner
    offer.name                              = name
    offer.instructions                      = instructions
    offer.prerequisite_offer_id             = prerequisite_offer_id
    offer.exclusion_prerequisite_offer_ids  = exclusion_prerequisite_offer_ids
    offer.x_partner_prerequisites           = x_partner_prerequisites
    offer.x_partner_exclusion_prerequisites = x_partner_exclusion_prerequisites
    offer
  end

  def create_primary_offer
    offer                  = build_offer
    offer.id               = id
    offer.url              = app.store_url
    offer.device_types     = app.primary_offer.device_types
    offer.price            = offer_price
    offer.bid              = offer.min_bid
    offer.name_suffix      = "action"
    offer.icon_id_override = app.primary_app_metadata.id if app.primary_app_metadata
    offer.app_metadata     = app.primary_app_metadata if app.primary_app_metadata
    offer.save!
  end

  def create_secondary_offers
    app.app_metadata_mappings.each do |distribution|
      unless distribution.is_primary
        create_offer_from_app_metadata(distribution.app_metadata)
      end
    end
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id              = partner_id if partner_id_changed?
      offer.name                    = name if name_changed?
      offer.instructions            = instructions if instructions_changed? && !offer.instructions_overridden?
      offer.hidden                  = hidden if hidden_changed?
      offer.price                   = offer_price(offer.app_metadata)
      if offer.price_changed? && offer.bid < offer.min_bid
        offer.bid                   = offer.min_bid
      end
      offer.prerequisite_offer_id             = prerequisite_offer_id             if prerequisite_offer_id_changed?
      offer.exclusion_prerequisite_offer_ids  = exclusion_prerequisite_offer_ids  if exclusion_prerequisite_offer_ids_changed?
      offer.x_partner_prerequisites           = x_partner_prerequisites           if x_partner_prerequisites_changed?
      offer.x_partner_exclusion_prerequisites = x_partner_exclusion_prerequisites if x_partner_exclusion_prerequisites_changed?
      offer.save! if offer.changed?
    end
  end

  def set_variable_name
    self.variable_name = 'TJC_' + name.gsub(/[^[:alnum:]]/, '_').upcase
  end

end
