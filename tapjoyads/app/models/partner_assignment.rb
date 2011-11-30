class PartnerAssignment < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :user
  belongs_to :partner

  validates_presence_of :user, :partner
  validates_uniqueness_of :user_id, :scope => [ :partner_id ]

  after_create :set_reseller

  private

  def set_reseller
    partner.reseller_id = user.reseller_id
    partner.save! if partner.changed?
    true
  end

end
