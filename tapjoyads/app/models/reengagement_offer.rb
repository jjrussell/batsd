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

  def self.enable_all(app_id)
    ReengagementOffer.set_enabled(app_id, true)  
  end

  def self.disable_all(app_id)
    ReengagementOffer.set_enabled(app_id, false)  
  end

  def enable
    set_enabled(true)
  end

  def disable
    set_enabled(false)
  end

  def self.cache_list(app_id)
    reengagement_offers = ReengagementOffer.visible.find_all_by_app_id(app_id, :order => 'day_number ASC')
    response = Mc.put("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION}", reengagement_offers, false, 1.day)
  end

  def self.find_list_in_cache(app_id)
    Mc.get("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION}")
  end
  
  def cache_list
    ReengagementOffer.cache_list app_id
  end

  private

  def set_enabled(enabled_value, refresh_cache=true)
    self.enabled = enabled_value
    self.save!
    offers.each do |offer|
      offer.user_enabled = enabled_value
      offer.save!
    end
    if refresh_cache
      if enabled_value
        cache_list
      else
        Mc.delete("mysql.reengagement_offers.#{app_id}.#{SCHEMA_VERSION})") unless enabled_value
      end
    end
  end

  def create_day_zero_reengagement(app_id, partner_id)
  end

  def self.set_enabled(app_id, enabled_value)
    puts "========================= setting to #{enabled_value}"
    reengagement_offers = ReengagementOffer.visible.find_all_by_app_id(app_id)
    reengagement_offers.each do |r|
      enabled_value ? r.enable : r.disable
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
