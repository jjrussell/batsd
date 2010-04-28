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
  
  validates_numericality_of :balance, :pending_earnings, :only_integer => true, :allow_nil => false
  
  cattr_reader :per_page
  @@per_page = 20
  
  named_scope :to_payout, :conditions => 'pending_earnings >= 10000', :order => 'pending_earnings DESC'
  
  def payout_cutoff_date(reference_date = nil)
    reference_date ||= Time.zone.now
    case payout_frequency
    when 'semimonthly'
      reference_date.day > 15 ? (reference_date.beginning_of_month + 15.days) : reference_date.beginning_of_month
    else
      reference_date.beginning_of_month
    end
  end
end
