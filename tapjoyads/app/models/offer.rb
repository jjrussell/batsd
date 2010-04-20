class Offer < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :partner
  belongs_to :item, :polymorphic => true
  
  validates_presence_of :partner, :item, :name, :url
  validates_numericality_of :price, :payment, :ordinal, :only_integer => true
  validates_inclusion_of :pay_per_click, :in => [ true, false ]
  validates_inclusion_of :item_type, :in => %w( App EmailOffer )
  
end
