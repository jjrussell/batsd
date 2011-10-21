class EditorsPick < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer

  validates_presence_of :scheduled_for, :offer
  validate :scheduled_for_the_future

  named_scope :upcoming, :conditions => 'activated_at IS NULL and expired_at IS NULL', :order => 'scheduled_for'
  named_scope :to_activate, lambda { { :conditions => [ 'scheduled_for <= ? AND activated_at IS NULL AND expired_at IS NULL', Time.zone.now ], :order => 'scheduled_for' } }
  named_scope :active, :conditions => [ 'activated_at IS NOT NULL AND expired_at IS NULL' ], :order => 'display_order desc'
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

  def self.cached_active(platform)
    if platform == 'android'
      Mc.distributed_get_and_put('cached_apps.active_editors_picks.android', false, 1.minute) do
        picks = self.active.first(10)
        picks.map { |p| CachedApp.new(p.offer, p.description) }
      end
    else
      Mc.distributed_get_and_put('cached_apps.active_editors_picks.iphone', false, 1.minute) do
        picks = self.active.first(10)
        picks.map { |p| CachedApp.new(p.offer, p.description) }
      end
    end
  end
private

  def scheduled_for_the_future
    errors.add :scheduled_for, 'must be in the future.' if !activated_at? && scheduled_for && (scheduled_for < Time.zone.now - 1.hour)
  end

end
