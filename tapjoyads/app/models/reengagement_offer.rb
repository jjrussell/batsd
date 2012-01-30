class ReengagementOffer < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  belongs_to :app
  belongs_to :partner
  belongs_to :currency
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :offers, :as => :item

  validates_presence_of :partner, :app, :instructions, :reward_value
  validates_numericality_of :reward_value, :greater_than_or_equal_to => 0

  after_create :create_primary_offer
  after_update :update_offers
  after_destroy :update_offers
  after_cache :cache_list

  delegate :instructions_overridden, :to => :primary_offer
  delegate :get_offer_device_types, :store_id, :store_url, :large_download?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  named_scope :visible, :conditions => { :hidden => false }
  named_scope :active, :conditions => { :hidden => false, :enabled => true }
  named_scope :inactive, :conditions => { :hidden => false, :enabled => false }

  def self.campaign_length(app_id)
    ReengagementOffer.visible.find_all_by_app_id(app_id).length
  end

  def campaign_length
    ReengagementOffer.campaign_length(app_id)
  end

  def self.enable_for_app!(app_id)
    ReengagementOffer.inactive.find_all_by_app_id(app_id).map(&:enable!)
  end

  def self.disable_for_app!(app_id)
    ReengagementOffer.active.find_all_by_app_id(app_id).map(&:disable!)
    ReengagementOffer.uncache_list app_id
  end

  def remove!
    self.hidden = true
    disable!
  end

  def disable!
    self.enabled = false
    save_enabled! and uncache if self.changed?
  end

  def enable!
    self.enabled = true
    save_enabled! and cache if self.changed?
  end

  def uncache
    ReengagementOffer.uncache id
  end

  def self.uncache(id)
    Mc.delete("mysql.reengagement_offer.#{id}.#{SCHEMA_VERSION})") if Mc.get("mysql.reengagement_offer.#{id}.#{SCHEMA_VERSION})").present?
  end

  def self.uncache_list(app_id)
    Mc.delete("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION})") if self.find_list_in_cache(app_id).present?
  end

  def self.cache_list(app_id)
    reengagement_offers = ReengagementOffer.active.find_all_by_app_id(app_id, :order => 'day_number ASC')
    response = Mc.put("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION}", reengagement_offers, false, 1.day)
  end

  def self.find_list_in_cache(app_id)
    Mc.get("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION}")
  end
  
  def cache_list
    ReengagementOffer.cache_list app_id
  end

  private

  def save_enabled!
    self.save!
    offers.each do |offer|
      offer.user_enabled = self.enabled
      offer.save!
    end
  end

  def find_list_in_cache
    Mc.get("mysql.reengagement_offer.#{app_id}.#{SCHEMA_VERSION}")
  end

  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id                = id
    offer.partner           = partner
    offer.name              = "reengagement_offer.#{app_id}.#{id}"
    offer.url               = app.store_url
    offer.payment           = 0
    offer.instructions      = instructions
    offer.device_types      = app.primary_offer.device_types
    offer.reward_value      = reward_value
    offer.price             = 0
    offer.bid               = 0
    offer.name_suffix       = 'reengagement'
    offer.third_party_data  = 0
    offer.icon_id_override  = app.id
    offer.user_enabled      = false
    offer.tapjoy_enabled    = true
    offer.save!
  end

  def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id
      offer.user_enabled     = enabled
      offer.hidden           = hidden
      offer.reward_value     = reward_value
      offer.instructions     = instructions
      offer.third_party_data = prerequisite_offer_id
      offer.save! if offer.changed?
    end
  end
  
end
