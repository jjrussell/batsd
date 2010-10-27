class RankBoost < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :offer
  
  validates_presence_of :start_time, :end_time, :id, :offer, :amount
  validate :check_times
  
  named_scope :active, lambda { { :conditions => [ "start_time <= ? AND end_time >= ?", Time.zone.now, Time.zone.now ]} }
  
  def partner_id
    offer.partner_id
  end
  
  def active?
    now = Time.zone.now
    start_time <= now && end_time >= now
  end
  
private
  
  def check_times
    if (start_time.present? && end_time.present? && start_time >= end_time)
      errors.add :end_time, "must be after Start Time"
    end
  end

end
