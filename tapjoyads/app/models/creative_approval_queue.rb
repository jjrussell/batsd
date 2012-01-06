class CreativeApprovalQueue < ActiveRecord::Base
  set_table_name 'creative_approval_queue'

  belongs_to :offer
  belongs_to :user

  validates_presence_of :size

  def approve!
    offer.approve_banner_creative(size)
    offer.save
  end

  def reject!
    offer.remove_banner_creative(size)
    offer.save
  end
end
