# == Schema Information
#
# Table name: creative_approval_queue
#
#  id       :integer(4)      not null, primary key
#  offer_id :string(36)      not null
#  user_id  :string(36)
#  size     :text
#

class CreativeApprovalQueue < ActiveRecord::Base
  set_table_name 'creative_approval_queue'

  belongs_to :offer
  belongs_to :user

  validates_presence_of :size
  validates_uniqueness_of :size, :scope => :offer_id

  def approve!
    offer.approve_banner_creative(size)
    offer.save # after_save on offer will remove this object
  end

  def reject!
    offer.remove_banner_creative(size)
    offer.save # after_save on offer will remove this object
  end
end
