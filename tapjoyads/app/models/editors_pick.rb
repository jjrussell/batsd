# == Schema Information
#
# Table name: editors_picks
#
#  id             :string(36)      not null, primary key
#  offer_id       :string(36)      not null
#  display_order  :integer(4)      default(100), not null
#  description    :string(255)     default(""), not null
#  internal_notes :string(255)     default(""), not null
#  scheduled_for  :datetime        not null
#  activated_at   :datetime
#  expired_at     :datetime
#  created_at     :datetime
#  updated_at     :datetime
#

class EditorsPick < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer

  validates_presence_of :scheduled_for, :offer
  validate :scheduled_for_the_future

  scope :upcoming, :conditions => 'activated_at IS NULL and expired_at IS NULL', :order => 'scheduled_for'
  scope :to_activate, lambda { { :conditions => [ 'scheduled_for <= ? AND activated_at IS NULL AND expired_at IS NULL', Time.zone.now ], :order => 'scheduled_for' } }
  scope :active, :conditions => [ 'activated_at IS NOT NULL AND expired_at IS NULL' ], :order => 'display_order desc'
  scope :expired, :conditions => 'expired_at', :order => 'expired_at desc'
  scope :by_platform, lambda { |platform| {
    :conditions => ["apps.platform = ? AND activated_at IS NOT NULL", platform],
    :joins => "join apps ON editors_picks.offer_id = apps.id",
    :order => "display_order DESC", :limit => 10
  } }

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
    platform = 'iphone' unless platform == 'android'

    Mc.distributed_get_and_put("cached_apps.active_editors_picks.#{platform}", false, 1.minute) do
      picks = EditorsPick.active.by_platform(platform)
      picks = EditorsPick.by_platform(platform) if picks.empty?
      picks.map { |p| CachedApp.new(p.offer, :description => p.description) }
    end
  end
private

  def scheduled_for_the_future
    errors.add :scheduled_for, 'must be in the future.' if !activated_at? && scheduled_for && (scheduled_for < Time.zone.now - 1.hour)
  end

end
