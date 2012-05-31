# == Schema Information
#
# Table name: deeplink_offers
#
#  id          :string(36)      not null, primary key
#  app_id      :string(36)      not null
#  currency_id :string(36)      not null
#  partner_id  :string(36)      not null
#  name        :string(255)     not null
#  created_at  :datetime
#  updated_at  :datetime
#

class DeeplinkOffer < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'

  belongs_to :partner
  belongs_to :app
  belongs_to :currency

  delegate :tapjoy_enabled, :user_enabled, :to => :primary_offer

  validates_presence_of :partner, :app, :currency, :name
  before_validation :set_name_from_currency
  after_create :create_primary_offer

  private

  def set_name_from_currency
    self.name = "Earn #{currency.name} in #{app.name}"
  end

  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.url = "#{WEBSITE_URL}/earn?eid=#{ObjectEncryptor.encrypt(currency_id)}&udid=TAPJOY_UDID"
    offer.price = 0
    offer.bid = 1
    offer.rewarded = true
    offer.publisher_app_whitelist = self.app_id
    offer.approved_sources = %w(offerwall)
    offer.tapjoy_enabled = true
    offer.user_enabled = true
    offer.pay_per_click = true
    offer.multi_complete = true
    offer.interval = 1.hour.to_i
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.icon_id_override = app_id
    offer.save!
  end
end
