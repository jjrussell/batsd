# == Schema Information
#
# Table name: rank_boosts
#
#  id         :string(36)      not null, primary key
#  offer_id   :string(36)      not null
#  start_time :datetime        not null
#  end_time   :datetime        not null
#  amount     :integer(4)      not null
#  created_at :datetime
#  updated_at :datetime
#

class RankBoost < ActiveRecord::Base
  OPTIMIZED_RANK_BOOST_MAX = 1000

  include UuidPrimaryKey

  RANK_SCORE_THRESHOLD = OPTIMIZED_RANK_BOOST_MAX

  belongs_to :offer

  validates_presence_of :start_time, :end_time, :offer
  validates_numericality_of :amount, :allow_nil => false, :only_integer => true
  validate :check_times
  validate :check_optimized_boost_rank_value

  after_save :calculate_rank_boost_for_offer

  scope :active, lambda { { :conditions => [ "start_time <= ? AND end_time > ?", Time.zone.now, Time.zone.now ] } }
  scope :for_offer, lambda { |offer_id| { :conditions => [ "offer_id = ?", offer_id] } }
  scope :optimized, lambda { { :conditions => { :optimized => true } } }
  scope :not_optimized, lambda { { :conditions => { :optimized => false } } }

  def partner_id
    offer.partner_id
  end

  def active?
    now = Time.zone.now
    start_time <= now && end_time > now
  end

  def deactivate!
    self.end_time = Time.zone.now if (end_time > Time.zone.now)
    self.save
  end

private

  def check_times
    if (start_time.present? && end_time.present? && start_time >= end_time)
      errors.add :end_time, "must be after Start Time"
    end
  end

  def calculate_rank_boost_for_offer
    self.optimized? ? offer.calculate_optimized_rank_boost! : offer.calculate_rank_boost!
  end

  def check_optimized_boost_rank_value
    errors.add :amount, "Amount must be <= #{OPTIMIZED_RANK_BOOST_MAX}" if amount.present? && amount > OPTIMIZED_RANK_BOOST_MAX && optimized?
  end
end
