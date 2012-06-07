# == Schema Information
#
# Table name: brands
#
#  id         :string(36)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Brand < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :offers, :through => :brand_offer_mappings
  has_many :brand_offer_mappings

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
end
