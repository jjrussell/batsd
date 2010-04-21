class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  
  IPHONE_DEVICES = %w( iphone itouch ipad )
  ANDROID_DEVICES = %w( android )
  ALL_DEVICES = IPHONE_DEVICES + ANDROID_DEVICES
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url
  validates_numericality_of :price, :payment, :ordinal, :only_integer => true
  validates_numericality_of :actual_payment, :only_integer => true, :allow_nil => true
  validates_inclusion_of :pay_per_click, :user_enabled, :tapjoy_enabled, :allow_negative_balance, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer )
  
  def cost
    price > 0 ? 'Paid' : 'Free'
  end
  
end
