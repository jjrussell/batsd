# == Schema Information
#
# Table name: payout_freezes
#
#  id          :string(36)      not null, primary key
#  enabled     :boolean(1)      default(TRUE), not null
#  enabled_at  :datetime
#  disabled_at :datetime
#  enabled_by  :string(255)
#  disabled_by :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class PayoutFreeze < ActiveRecord::Base
  include UuidPrimaryKey

  scope :enabled, :conditions => 'enabled = true'
  scope :by_enabled_at, :order => 'enabled_at DESC'

  def self.enabled?
    enabled.count > 0
  end

end
