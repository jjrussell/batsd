class ReengagementOffer < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :app
  belongs_to :partner
  belongs_to :currency
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :offers, :as => :item

  #accepts_nested_attributes_for :primary_offer

  validates_presence_of :partner, :app, :instructions, :reward_value
  validates_numericality_of :reward_value

      # t.guid :app_id, :null => false
      # t.guid :partner_id, :null => false
      # t.guid :currency_id, :null => false
      # t.guid :prerequisite_offer_id
      # t.text :instructions
      # t.integer :day_number, :null => false

  after_create :create_primary_offer
  after_update :update_offers

  delegate :get_offer_device_types, :store_id, :store_url, :large_download?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  # def user_enabled=(enabled)
  #   @user_enabled = enabled
  #   primary_offer.user_enabled = enabled if primary_offer
  # end

  # def user_enabled?
  #   @user_enabled ||= primary_offer ? primary_offer.user_enabled? : false
  # end

  # def reward_value
  #   primary_offer.nil? ? 0 : primary_offer.reward_value
  # end

  # def reward_value=(rv)
  #   primary_offer.nil? ? 0 : primary_offer.reward_value = rv
  # end
  # def reward_value=

  

  private

  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id                = id
    offer.partner           = partner
    offer.name              = "reengagement_offer.#{app.id}.#{id}"
    offer.url               = app.store_url
    offer.instructions      = instructions
    offer.device_types      = app.primary_offer.device_types
    offer.reward_value      = reward_value
    offer.price             = 0
    offer.bid               = 0
    offer.name_suffix       = 'reengagement'
    offer.third_party_data  = 0
    offer.icon_id_override  = app.id
    offer.user_enabled      = false
    offer.save!
    puts "Created primary offer with id #{offer.id}"
  end

 def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id
      offer.hidden           = hidden
      offer.reward_value     = reward_value
      offer.instructions     = instructions
      offer.third_party_data = prerequisite_offer_id
      offer.save! if offer.changed?
    end
  end
  
end
