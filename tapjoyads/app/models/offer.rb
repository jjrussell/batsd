class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  
  APPLE_DEVICES = %w( iphone itouch ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = APPLE_DEVICES + ANDROID_DEVICES
  
  has_many :advertiser_conversions, :class_name => 'Conversion', :foreign_key => :advertiser_offer_id
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url, :instructions, :time_delay
  validates_numericality_of :price, :ordinal, :only_integer => true
  validates_numericality_of :payment, :only_integer => true, :if => Proc.new { |offer| offer.tapjoy_enabled? && offer.user_enabled? }
  validates_numericality_of :actual_payment, :only_integer => true, :allow_nil => true
  validates_numericality_of :conversion_rate, :show_rate, :greater_than_or_equal_to => 0
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :credit_card_required, :self_promote_only, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer OfferpalOffer RatingOffer )
  
  named_scope :enabled_offers, {:joins => :partner, :conditions => "payment > 0 and tapjoy_enabled = true and user_enabled = true and partners.balance > 0", :order => "ordinal ASC"}
  named_scope :classic_offers, {:conditions => "item_type in ('OfferpalOffer', 'RatingOffer')", :order => "ordinal ASC"}
  
  def cost
    price > 0 ? 'Paid' : 'Free'
  end
  
end
