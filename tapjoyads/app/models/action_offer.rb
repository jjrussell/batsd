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
  
  delegate :user_enabled?, :tapjoy_enabled?, :bid, :description, :min_bid, :daily_budget, :integrated?, :to => :primary_offer
  
  delegate :is_android?, :store_id, :store_url, :large_download?, :supported_devices, :to => :app
  
private

  def create_primary_offer
    offer                  = Offer.new(:item => self)
    offer.id               = id
    offer.partner          = partner
    offer.name             = name
    offer.instructions     = "Follow the instructions to receive credit."
    offer.description      = offer.instructions
    offer.url              = "#{API_URL}/action_offers/#{self.id}"
    offer.device_types     = app.primary_offer.device_types
    offer.bid              = 0
    offer.price            = 0
    offer.time_delay       = 'in seconds'
    offer.name_suffix      = 'action'
    offer.third_party_data = prerequisite_offer_id
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id if partner_id_changed?
      offer.app_id           = app_id if app_id_changed?
      offer.name             = name if name_changed?
      offer.hidden           = hidden if hidden_changed?
      offer.third_party_data = prerequisite_offer_id if prerequisite_offer_id_changed?
      offer.save! if offer.changed?
    end
  end
  
  def set_variable_name
    self.variable_name = 'TJC_' + name.gsub(/[^[:alnum:]]/, '_').upcase
  end
end
