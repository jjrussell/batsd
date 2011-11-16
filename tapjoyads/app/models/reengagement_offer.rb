class ReengagementOffer < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :app
  belongs_to :partner
  belongs_to :prerequisite_offer, :class_name => 'Offer'

  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  has_many :offers, :as => :item

  validates_presence_of :prerequisite_offer, :if => Proc.new { |action_offer| action_offer.prerequisite_offer_id? }
  validates_presence_of :partner, :app, :name, :instructions, :reward_value

  after_create :create_primary_offer
  after_update :update_offers

  delegate :tapjoy_enabled?, :bid, :min_bid, :daily_budget, :integrated?, :to => :primary_offer
  delegate :get_offer_device_types, :store_id, :store_url, :large_download?, :supported_devices, :platform, :get_countries_blacklist, :countries_blacklist, :primary_category, :user_rating, :info_url, :to => :app

  def user_enabled=(enabled)
    @user_enabled = enabled
    primary_offer.user_enabled = enabled if primary_offer
  end

  def user_enabled?
    @user_enabled ||= primary_offer ? primary_offer.user_enabled? : false
  end
  
  private

  def create_primary_offer
    offer = Offer.create!([
      :item             => self,
      :id               => id,
      :partner          => partner,
      :name             => name,
      :url              => app.store_url,
      :instructions     => instructions,
      :device_types     => app.primary_offer.device_types,
      :reward_value     => reward_value,
      :price            => 0,
      :bid              => 0,
      :name_suffix      => 'reengagement',
      :third_party_data => prerequisite_offer_id,
      :icon_id_override => app_id,
      :user_enabled     => user_enabled?
    ])
  end

 def update_offers
    offers.each do |offer|
      offer.partner_id       = partner_id if partner_id_changed?
      offer.icon_id_override = app_id if app_id_changed? && app_id_was == offer.icon_id_override
      offer.url              = app.store_url unless offer.url_overridden?
      offer.name             = name if name_changed?
      offer.instructions     = instructions if instructions_changed?
      offer.hidden           = hidden if hidden_changed?
      offer.price            = prerequisite_offer_id? ? 0 : app.price
      offer.bid = offer.min_bid if offer.price_changed? && offer.bid < offer.min_bid
      offer.third_party_data = prerequisite_offer_id if prerequisite_offer_id_changed?
      offer.save! if offer.changed?
    end
  end
  
end
