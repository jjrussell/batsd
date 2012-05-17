class PayoutFreeze < ActiveRecord::Base
  include UuidPrimaryKey

  scope :enabled, :conditions => 'enabled = true'
  scope :by_enabled_at, :order => 'enabled_at DESC'

  def self.enabled?
    enabled.count > 0
  end

end
