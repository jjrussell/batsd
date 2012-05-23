# == Schema Information
#
# Table name: partner_assignments
#
#  id         :string(36)      not null, primary key
#  user_id    :string(36)      not null
#  partner_id :string(36)      not null
#

class PartnerAssignment < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :user
  belongs_to :partner

  validates :user_id, :partner_id, :presence => true
  validates :user_id, :uniqueness => { :scope => [ :partner_id ] }

  before_create :set_reseller

  delegate :name, :to => :partner

  def <=>(other)
    name.to_s <=> other.name.to_s
  end

  private

  def set_reseller
    if user.reseller_id?
      if partner.reseller_id? && partner.reseller_id != user.reseller_id
        return false
      else
        partner.reseller_id = user.reseller_id
        partner.save! if partner.changed?
      end
    end
    true
  end

end
