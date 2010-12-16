class MonthlyAccounting < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  validates_presence_of :partner
  validates_numericality_of :month, :only_integer => true, :allow_nil => false, :greater_than => 0, :less_than => 13
  validates_numericality_of :year, :only_integer => true, :allow_nil => false, :greater_than => 2007
  validates_uniqueness_of :partner_id, :scope => [ :month, :year ]

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
      orders = Order.created_between(start_time, end_time).sum(:amount, :conditions => [ "status = ? AND partner_id = ?", 1, partner.id ], :group => :payment_method)
    end
    self.website_orders   = orders[0] || 0
    self.invoiced_orders  = orders[1] || 0
    self.marketing_orders = orders[2] || 0
    self.transfer_orders  = orders[3] || 0
    Partner.using_slave_db do
      self.spend = Conversion.created_between(start_time, end_time).sum(:advertiser_amount, :conditions => [ "advertiser_offer_id IN (?)", partner.offer_ids ])
    end
    self.ending_balance = beginning_balance + website_orders + invoiced_orders + marketing_orders + transfer_orders + spend
    
    # pending earnings components
    payouts = {}
    Payout.using_slave_db do
      payouts = Payout.created_between(start_time, end_time).sum(:amount, :conditions => [ "status = ? AND partner_id = ?", 1, partner.id ], :group => :payment_method)
    end
    self.payment_payouts  = (payouts[1] || 0).abs
    self.transfer_payouts = (payouts[3] || 0).abs
    Partner.using_slave_db do
      self.earnings = Conversion.created_between(start_time, end_time).sum(:publisher_amount, :conditions => [ "publisher_app_id IN (?)", partner.app_ids ])
    end
    self.ending_pending_earnings = beginning_pending_earnings + payment_payouts + transfer_payouts + earnings
    
    save!
  end

  def start_time
    Time.zone.parse("#{year}-#{month}-01")
  end

  def end_time
    start_time.next_month
  end

  def total_orders
    website_orders + invoiced_orders + marketing_orders + transfer_orders
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
