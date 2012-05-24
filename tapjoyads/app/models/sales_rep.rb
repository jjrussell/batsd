# == Schema Information
#
# Table name: sales_reps
#
#  id           :string(36)      not null, primary key
#  sales_rep_id :string(36)      not null
#  offer_id     :string(36)      not null
#  start_date   :datetime        not null
#  end_date     :datetime
#

class SalesRep < ActiveRecord::Base
  include UuidPrimaryKey

  attr_accessible :sales_rep_id, :start_date, :end_date

  belongs_to :sales_rep, :class_name => 'User'
  belongs_to :offer

  validate :start_date_before_end_date
  validates_presence_of :offer_id, :sales_rep_id, :start_date
  validates_uniqueness_of :sales_rep_id, :scope => :offer_id

  def to_s
    sales_rep.to_s
  end

  private

  def start_date_before_end_date
    return unless start_date and end_date # handled by validates_presence_of
    if start_date > end_date
      errors.add(:start_date, 'Start date cannot be after end date')
    end
  end

end
