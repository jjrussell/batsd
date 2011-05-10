class ActionOffer < ActiveRecord::Base
  include UuidPrimaryKey
  include MemcachedRecord
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  belongs_to :app
  belongs_to :prerequisite_offer, :class_name => 'Offer'
  
  validates_presence_of :partner, :app, :name, :variable_name
  validates_uniqueness_of :variable_name, :scope => :app_id, :case_sensitive => false
  validates_presence_of :instructions, :unless => :new_record?
  validates_presence_of :prerequisite_offer, :if => Proc.new { |action_offer| action_offer.prerequisite_offer_id? }
  
  named_scope :visible, :conditions => { :hidden => false }
  
  accepts_nested_attributes_for :primary_offer
  
  before_validation :set_variable_name
  after_create :create_primary_offer
  after_update :update_offers
  
  delegate :user_enabled?, :tapjoy_enabled?, :bid, :min_bid, :daily_budget, :integrated?, :to => :primary_offer
  
  delegate :is_android?, :store_id, :store_url, :large_download?, :supported_devices, :to => :app

  def toggle_user_enabled
    primary_offer.toggle_user_enabled
    primary_offer.save
  end

private

  def create_primary_offer
    offer                  = Offer.new(:item => self)
    offer.id               = id
    offer.partner          = partner
    offer.name             = name
    offer.url              = app.direct_store_url
    offer.instructions     = instructions
    offer.device_types     = app.primary_offer.device_types
    offer.bid              = offer.min_bid
    offer.price            = prerequisite_offer_id? ? 0 : app.price
    offer.name_suffix      = 'action'
    offer.third_party_data = prerequisite_offer_id
    offer.icon_id_override = app_id
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id if partner_id_changed?
      offer.icon_id_override = app_id if app_id_changed? && app_id_w
      offer.url              = app.direct_store_url
      offer.name             = name if name_changed?
      offer.instructions     = instructions if instructions_changed?
      offer.hidden           = hidden if hidden_changed?
      offer.price            = prerequisite_offer_id? ? 0 : app.price
      offer.third_party_data = prerequisite_offer_id if prerequisite_offer_id_changed?
      offer.save! if offer.changed?
    end
  end
  
  def set_variable_name
    self.variable_name = 'TJC_' + name.gsub(/[^[:alnum:]]/, '_').upcase
  end
end
