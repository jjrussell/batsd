class SpendShare < ActiveRecord::Base
  include UuidPrimaryKey

  validates_numericality_of :ratio, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1
  validates_uniqueness_of :effective_on
  validates_each :effective_on, :allow_blank => false, :allow_nil => false do |record, attribute, value|
    if value > Date.today
      record.errors.add(attribute, "is in the future")
    end
  end

  named_scope :effective, lambda { |date| { :conditions => { :effective_on => date.to_date } } }

  def self.current_ratio
    Mc.distributed_get_and_put("spend_share.ratio.#{Date.today}") do
      current.ratio
    end
  end

  def self.current
    for_date(Date.today)
  end

  def self.for_date(date)
    effective(date).first || create_for_date!(date)
  end

  def self.create_for_date!(date)
    sum_network_costs    = NetworkCost.created_between(date - 30.days, date).sum(:amount)
    orders               = Order.created_between(date - 30.days, date)
    sum_all_orders       = orders.collect(&:amount).sum + sum_network_costs
    sum_website_orders   = orders.select{ |o| o.payment_method == 0 }.collect(&:amount).sum
    sum_marketing_orders = orders.select{ |o| o.payment_method == 2 }.collect(&:amount).sum + sum_network_costs

    if sum_all_orders == 0
      ratio = 1
    else
      ratio = (sum_all_orders - sum_marketing_orders - (0.025 * sum_website_orders)) / sum_all_orders
    end

    create!(:effective_on => date, :ratio => ratio)
  end

end
