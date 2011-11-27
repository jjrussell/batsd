class SurveyOffer < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :survey_questions
  has_one :offer, :as => :item
  has_one :primary_offer,
    :class_name => 'Offer',
    :as => :item,
    :foreign_key => :item_id

  belongs_to :partner

  attr_accessor :bid_price

  accepts_nested_attributes_for :survey_questions

  validates_presence_of :partner, :name
  validates_presence_of :bid_price, :on => :create

  before_validation_on_create :assign_partner_id
  after_create :create_primary_offer
  after_update :update_offer

  named_scope :visible, :conditions => { :hidden => false }

  def bid
    primary_offer ? primary_offer.bid : @bid_price
  end

  def bid=(price)
    @bid_price = price
  end

  def hide!
    self.hidden = true
    self.save!
  end

  def to_s
    name
  end

  def enabled?
    primary_offer.is_enabled?
  end

  def enabled=(value)
    primary_offer.user_enabled = value
    primary_offer.save!
  end

private

  def create_primary_offer
    Offer.create!({
      :item => self,
      :id => id,
      :partner => partner,
      :name => name,
      :price => 0,
      :url => '?',
      :bid => @bid_price,
      :device_types => Offer::ALL_DEVICES.to_json,
      :tapjoy_enabled => true,
    })
  end

  def update_offer
    offer.partner_id = partner_id
    offer.name = name
    offer.hidden = hidden
    offer.bid = @bid_price unless @bid_price.nil?
    offer.save!
  end

  def assign_partner_id
    self.partner_id = Partner::THE_REAL_TAPJOY_PARTNER_ID
  end
end
