class Partner < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :orders
  has_many :payouts
  has_many :partner_assignments
  has_many :users, :through => :partner_assignments
  has_many :apps
  has_many :email_offers
  has_many :offers
  has_many :publisher_conversions, :through => :apps
  has_many :advertiser_conversions, :through => :offers
  
  validates_numericality_of :balance, :pending_earnings, :next_payout_amount, :only_integer => true, :allow_nil => false
  
  cattr_reader :per_page
  @@per_page = 20
  
  named_scope :to_calculate_next_payout_amount, :conditions => 'pending_earnings >= 10000'
  named_scope :to_payout, :conditions => 'next_payout_amount >= 10000'
  
  def payout_cutoff_date(reference_date = nil)
    reference_date ||= Time.zone.now
    reference_date -= 3.days
    case payout_frequency
    when 'semimonthly'
      reference_date.day > 15 ? (reference_date.beginning_of_month + 15.days) : reference_date.beginning_of_month
    else
      reference_date.beginning_of_month
    end
  end
  
  def calculate_next_payout_amount(do_save = false)
    Partner.transaction do
      self.lock!('FOR UPDATE') if do_save
      self.reload
      self.next_payout_amount = pending_earnings - publisher_conversions.created_since(payout_cutoff_date).sum(:publisher_amount)
      self.save! if do_save
    end
  end
  
  def recalculate_balances(do_save = false)
    Partner.transaction do
      self.lock!('FOR UPDATE') if do_save
      orders_sum = self.orders.sum(:amount, :conditions => 'status = 1')
      payouts_sum = self.payouts.sum(:amount, :conditions => 'status = 1')
      publisher_conversions_sum = self.publisher_conversions.sum(:publisher_amount)
      advertiser_conversions_sum = self.advertiser_conversions.sum(:advertiser_amount)
      self.balance = orders_sum + advertiser_conversions_sum
      self.pending_earnings = publisher_conversions_sum - payouts_sum
      self.save! if do_save
    end
  end
  
end
