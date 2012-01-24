class PayoutFreeze < ActiveRecord::Base
  include UuidPrimaryKey

  named_scope :enabled, :conditions => 'enabled = true'
  named_scope :by_enabled_at, :order => 'enabled_at DESC'

  def self.enabled?
    enabled.count > 0
  end

end
