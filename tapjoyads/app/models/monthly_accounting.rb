class MonthlyAccounting < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  validates_presence_of :partner
  validates_numericality_of :month, :only_integer => true, :allow_nil => false, :greater_than => 0, :less_than => 13
  validates_numericality_of :year, :only_integer => true, :allow_nil => false, :greater_than => 2007
  validates_uniqueness_of :partner_id, :scope => [ :month, :year ]

  named_scope :since, lambda { |time| { :conditions => ["(year = ? AND month >= ?) OR (year > ?)", time.year, time.month, time.year] } }
  named_scope :prior_to, lambda { |time| { :conditions => ["(year = ? AND month < ?) OR (year < ?)", time.year, time.month, time.year] } }

  def self.expected_count
    now = Time.zone.now
    start = Time.zone.parse('2009-01-01')
    total = 0
    while start < now do
      total += Partner.count(:conditions => ["created_at < ?", start])
      start = start.next_month
    end
    total
  end

  def calculate_totals!
    last_month = partner.monthly_accountings.find_by_month_and_year((start_time - 1).month, (start_time - 1).year)
    if last_month.present?
      self.beginning_balance          = last_month.ending_balance
      self.beginning_pending_earnings = last_month.ending_pending_earnings
    else
      self.beginning_balance          = 0
      self.beginning_pending_earnings = 0
    end

    # balance components
    orders = {}
    Order.using_slave_db do
      orders = partner.orders.created_between(start_time, end_time).sum(:amount, :group => :payment_method)
    end
    self.website_orders            = orders[0] || 0
    self.invoiced_orders           = orders[1] || 0
    self.marketing_orders          = orders[2] || 0
    self.transfer_orders           = orders[3] || 0
    self.marketing_credits_orders  = orders[4] || 0
    Partner.using_slave_db do
      self.spend = partner.advertiser_conversions.created_between(start_time, end_time).sum(:advertiser_amount)
    end
    self.ending_balance = beginning_balance + website_orders + invoiced_orders + marketing_orders + transfer_orders + marketing_credits_orders + spend

    # pending earnings components
    payouts = {}
    Payout.using_slave_db do
      payouts = partner.payouts.created_between(start_time, end_time).sum(:amount, :conditions => "status = 1", :group => :payment_method)
    end
    self.payment_payouts  = (payouts[1] || 0) * -1
    self.transfer_payouts = (payouts[3] || 0) * -1
    Partner.using_slave_db do
      self.earnings = partner.publisher_conversions.created_between(start_time, end_time).sum(:publisher_amount)
    end
    EarningsAdjustment.using_slave_db do
      self.earnings_adjustments = partner.earnings_adjustments.created_between(start_time, end_time).sum(:amount)
    end
    self.ending_pending_earnings = beginning_pending_earnings + payment_payouts + transfer_payouts + earnings + earnings_adjustments

    save!
  end

  def start_time
    Time.zone.parse("#{year}-#{month}-01")
  end

  def end_time
    start_time.next_month
  end

  def total_orders
    website_orders + invoiced_orders + marketing_orders + transfer_orders + marketing_credits_orders
  end

  def total_payouts
    payment_payouts + transfer_payouts
  end

  def <=> other
    [year, month] <=> [other.year, other.month]
  end

  def to_date
    Date.parse("#{year}-#{month}-01")
  end

  def to_mmm_yyyy
    to_date.strftime("%B %Y")
  end
end
