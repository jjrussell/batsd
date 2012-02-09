class GlobalPromotedOffer < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :offer
  belongs_to :partner

  validates_presence_of :offer, :partner
end
