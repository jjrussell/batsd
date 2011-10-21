class PartnerAssignment < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :user
  belongs_to :partner

  validates_presence_of :user, :partner
  validates_uniqueness_of :user_id, :scope => [ :partner_id ]
end
