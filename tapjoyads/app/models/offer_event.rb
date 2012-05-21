# == Schema Information
#
# Table name: offer_events
#
#  id                  :string(36)      not null, primary key
#  offer_id            :string(36)      not null
#  daily_budget        :integer(4)
#  user_enabled        :boolean(1)
#  change_daily_budget :boolean(1)      default(FALSE), not null
#  change_user_enabled :boolean(1)      default(FALSE), not null
#  scheduled_for       :datetime        not null
#  ran_at              :datetime
#  disabled_at         :datetime
#  created_at          :datetime
#  updated_at          :datetime
#

class OfferEvent < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer

  validates_presence_of :scheduled_for, :offer
  validates_numericality_of :daily_budget, :only_integer => true, :greater_than_or_equal_to => 0, :if => Proc.new { |offer_event| offer_event.change_daily_budget? }
  validates_inclusion_of :user_enabled, :in => [ true, false ], :if => Proc.new { |offer_event| offer_event.change_user_enabled? }
  validate :offer_is_changed, :scheduled_for_the_future

  scope :to_run, lambda { { :conditions => [ 'scheduled_for <= ? AND ran_at IS NULL AND disabled_at IS NULL', Time.zone.now ], :order => 'scheduled_for' } }
  scope :completed, :conditions => 'ran_at'
  scope :disabled, :conditions => 'disabled_at'
  scope :upcoming, :conditions => 'ran_at IS NULL and disabled_at IS NULL', :order => 'scheduled_for'

  CHANGEABLE_ATTRIBUTES = [ :user_enabled, :daily_budget ]

  def run!
    OfferEvent.transaction do
      offer.user_enabled = user_enabled if change_user_enabled?
      offer.daily_budget = daily_budget if change_daily_budget?
      offer.save!

      self.ran_at = Time.zone.now
      save!
    end
  end

  def disable!
    self.disabled_at = Time.zone.now
    save!
  end

  def editable?
    !(ran_at || disabled_at)
  end

private

  def offer_is_changed
    errors.add :base, 'User Enabled or Daily Budget must be changed.' if !(change_user_enabled? || change_daily_budget?)
  end

  def scheduled_for_the_future
    errors.add :scheduled_for, 'must be in the future.' if scheduled_for && (scheduled_for < Time.zone.now) && editable?
  end

end
