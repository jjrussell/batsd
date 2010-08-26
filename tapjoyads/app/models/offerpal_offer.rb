class OfferpalOffer < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :offers, :as => :item
  has_one :primary_offer, :class_name => 'Offer', :as => :item, :conditions => 'id = item_id'
  
  belongs_to :partner
  
  validates_presence_of :partner, :offerpal_id, :name
  validates_uniqueness_of :offerpal_id
  
  after_create :create_primary_offer
  after_update :update_offers
  
  named_scope :visible, :conditions => { :hidden => false }
  
  attr_writer :url, :instructions, :time_delay, :credit_card_required, :payment
  
private
  
  def create_primary_offer
    offer = Offer.new(:item => self)
    offer.id = id
    offer.partner = partner
    offer.name = name
    offer.description = description
    offer.price = 0
    offer.device_types = Offer::ALL_DEVICES.to_json
    offer.url = @url
    offer.instructions = @instructions
    offer.time_delay = @time_delay
    offer.credit_card_required = @credit_card_required
    offer.payment = @payment
    offer.tapjoy_enabled = true
    offer.show_rate = 1.0
    offer.save!
  end
  
  def update_offers
    offers.each do |offer|
      offer.partner_id = partner_id if partner_id_changed?
      offer.name = name if name_changed?
      offer.description = description if description_changed?
      offer.url = @url unless @url.nil?
      offer.instructions = @instructions unless @instructions.nil?
      offer.time_delay = @time_delay unless @time_delay.nil?
      offer.credit_card_required = @credit_card_required unless @credit_card_required.nil?
      offer.payment = @payment unless @payment.nil?
      offer.hidden = hidden if hidden_changed?
      offer.save! if offer.changed?
    end
  end
  
end
