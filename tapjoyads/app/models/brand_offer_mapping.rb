class BrandOfferMapping < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer
  belongs_to :brand

  validates_presence_of :offer, :brand

end
