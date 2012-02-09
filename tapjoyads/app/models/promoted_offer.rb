class PromotedOffer < ActiveRecord::Base
  include UuidPrimaryKey
  belongs_to :offer
  belongs_to :app

  validates_presence_of :offer, :app
end
