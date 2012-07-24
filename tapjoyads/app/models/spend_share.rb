# == Schema Information
#
# Table name: spend_shares
#
#  id             :string(36)      not null, primary key
#  ratio          :float           not null
#  effective_on   :date            not null
#  created_at     :datetime
#  updated_at     :datetime
#  uncapped_ratio :float           not null
#

class SpendShare < ActiveRecord::Base
  include UuidPrimaryKey

  FIXED_RATIO = 0.91
  ALGORITHM_TRANSITION_DATE = Time.parse('2012-07-01 00:00:00 UTC').to_date

  OLD_MIN_RATIO = 0.8

  validates_numericality_of :ratio, :uncapped_ratio, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_uniqueness_of :effective_on
  validates_each :effective_on, :allow_blank => false, :allow_nil => false do |record, attribute, value|
    if value > Time.now.utc.to_date
      record.errors.add(attribute, "is in the future")
    end
  end

  scope :effective, lambda { |date| { :conditions => { :effective_on => date.to_date } } }
  scope :over_range, lambda { |start_time, end_time| { :conditions => ["effective_on >= ? AND effective_on <= ?", start_time.to_date, end_time.to_date] } }

  def self.current_ratio
    FIXED_RATIO
  end

  def self.current
    for_date(Time.now.utc.to_date)
  end

  def self.for_date(date)
    effective(date).first || create_for_date!(date)
  end

  def deduct_pct(field = :ratio)
    NumberHelper.number_to_percentage((1 - self[field]) * 100, :precision => 2)
  end

  def capped?
    uncapped_ratio < ratio
  end

  def self.create_for_date!(date)
    if date < ALGORITHM_TRANSITION_DATE  #old algorithm was based on actual costs
      sum_network_costs    = NetworkCost.for_date(date).sum(:amount)
      orders               = Order.created_between(date - 30.days, date)
      sum_all_orders       = orders.collect(&:amount).sum + sum_network_costs
      sum_website_orders   = orders.select{ |o| o.payment_method == 0 }.collect(&:amount).sum
      sum_marketing_orders = orders.select{ |o| o.payment_method == 2 || o.payment_method == 5 }.collect(&:amount).sum + sum_network_costs

      if sum_all_orders == 0
        uncapped_ratio = 1
      else
        uncapped_ratio = (sum_all_orders - sum_marketing_orders - (0.025 * sum_website_orders)) / sum_all_orders
      end

      ratio = [uncapped_ratio, OLD_MIN_RATIO].max
    else #now a fixed percentage
      ratio = FIXED_RATIO
      uncapped_ratio = FIXED_RATIO
    end
    create!(:effective_on => date, :ratio => ratio, :uncapped_ratio => uncapped_ratio)
  end

end
