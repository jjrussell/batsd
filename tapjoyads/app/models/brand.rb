class Brand < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :offers, :through => :brand_offer_mappings
  has_many :brand_offer_mappings

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
end
