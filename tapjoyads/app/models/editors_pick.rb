class EditorsPick < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer

  validates_presence_of :scheduled_for, :offer
  validate :scheduled_for_the_future

  named_scope :upcoming, :conditions => 'activated_at IS NULL and expired_at IS NULL', :order => 'scheduled_for'
  named_scope :to_activate, lambda { { :conditions => [ 'scheduled_for <= ? AND activated_at IS NULL AND expired_at IS NULL', Time.zone.now ], :order => 'scheduled_for' } }
  named_scope :active, lambda { { :conditions => [ 'activated_at IS NOT NULL AND expired_at IS NULL' ], :order => 'display_order desc' } }
  named_scope :expired, :conditions => 'expired_at', :order => 'expired_at desc'

  def activate!
    self.expired_at = nil
    self.activated_at = Time.zone.now
    save!
  end

  def expire!
    self.expired_at = Time.zone.now
    save!
  end

  def active?
    self.activated_at && !self.expired_at
  end

  def self.cached_active
    Mc.get_and_put('active_editors_picks', false, 1.minute) do
      self.active.first(10)
    end
  end
private

  def scheduled_for_the_future
    errors.add :scheduled_for, 'must be in the future.' if !activated_at? && scheduled_for && (scheduled_for < Time.zone.now - 1.hour)
  end

end
