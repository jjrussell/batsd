class MonthlyAccounting < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :partner

  validates_presence_of :partner
  validates_numericality_of :month, :only_integer => true, :allow_nil => false, :greater_than => 0, :less_than => 13
  validates_numericality_of :year, :only_integer => true, :allow_nil => false, :greater_than => 2007

  def self.update_partner_record(partner_id, options = {})
    month = options.delete(:month)
    year = options.delete(:year)
    
    partner = Partner.find(partner_id)
    
    return if partner.created_at.beginning_of_month > Time.zone.parse("#{year}-#{month}-01")
    
    record = MonthlyAccounting.find_by_partner_id_and_month_and_year(partner_id, month, year)
    
    if record.nil?
      #we don't have that record for this partner yet, so create records until we are up to date
      while record.nil? || record.month != month || record.year != year
        record = create_next_record(partner)
      end
    else
      #the record for this month already exists, so update it
      if record.updated_at < Time.zone.now - 1.hours
        create_or_update_record(partner, {
          :year => year, :month => month, 
          :beginning_balance => record.beginning_balance, :beginning_pending_earnings => record.beginning_pending_earnings })
      end
    end
    
  end

  def self.create_next_record(partner)

    last_record = MonthlyAccounting.find_by_partner_id(partner.id, :order => "year desc, month desc")
    
    if last_record.nil?
      
      next_year = partner.created_at.year
      next_month = partner.created_at.month
      
      beginning_balance = 0
      beginning_pending_earnings = 0
      
    else
      
      next_year = last_record.year
      next_month = last_record.month + 1
      
      if last_record.month == 12
        next_year += 1
        next_month = 1
      end
      
      beginning_balance = last_record.ending_balance
      beginning_pending_earnings = last_record.ending_pending_earnings
      
    end
    
    return create_or_update_record(partner, {
      :year => next_year, :month => next_month, 
      :beginning_balance => beginning_balance, :beginning_pending_earnings => beginning_pending_earnings })
    
  end
  
  def self.create_or_update_record(partner, options = {})
    year = options.delete(:year)
    month = options.delete(:month)
    beginning_balance = options.delete(:beginning_balance) { 0 }
    beginning_pending_earnings = options.delete(:beginning_pending_earnings) { 0 }
    start_time = Time.zone.parse("#{year}-#{month}-01")
    end_time = start_time + 1.month
    
    record = MonthlyAccounting.find_or_initialize_by_partner_id_and_month_and_year(partner.id, month, year)
    
    #Calculate the Balance side
    orders = nil
    Order.using_slave_db do
      orders = Order.sum(:amount, :conditions => "status = 1 and partner_id = '#{partner.id}' and created_at >= '#{start_time.to_s(:db)}' and created_at < '#{end_time.to_s(:db)}'", :group => :payment_method)
    end
    
    record.beginning_balance = beginning_balance    
    record.website_orders = orders[0] || 0
    record.invoiced_orders = orders[1] || 0
    record.marketing_orders = orders[2] || 0
    record.transfer_orders = orders[3] || 0
    Partner.using_slave_db do
      record.spend = Conversion.created_between(start_time, end_time).sum(:advertiser_amount, :conditions => [ "advertiser_offer_id IN (?)", partner.offer_ids ])
    end
    
    record.ending_balance = record.beginning_balance + 
      record.website_orders + record.invoiced_orders + record.marketing_orders + record.transfer_orders + 
      record.spend #this is a negative value
    
    #Calculate the Pending Earnings side
    payouts = nil
    Payout.using_slave_db do
      payouts = Payout.sum(:amount, :conditions => "status = 1 and partner_id = '#{partner.id}' and created_at >= '#{start_time.to_s(:db)}' and created_at < '#{end_time.to_s(:db)}'", :group => :payment_method)
    end
    
    record.beginning_pending_earnings = beginning_pending_earnings
    record.payment_payouts = (payouts[1] || 0) * -1
    record.transfer_payouts = (payouts[3] || 0) * -1
    Partner.using_slave_db do
      record.earnings = Conversion.created_between(start_time, end_time).sum(:publisher_amount, :conditions => [ "publisher_app_id IN (?)", partner.app_ids ])
    end
    
    record.ending_pending_earnings = record.beginning_pending_earnings +
      record.payment_payouts + record.transfer_payouts + #these are negative values
      record.earnings
    
    record.save!
    
    record
  end

  def orders
    website_orders + invoiced_orders + marketing_orders + transfer_orders
  end

  def payouts
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
