class Partner < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :orders
  has_many :payouts
  has_many :partner_assignments
  has_many :users, :through => :partner_assignments
  has_many :apps
  has_many :email_offers
  has_many :rating_offers
  has_many :offerpal_offers
  has_many :generic_offers
  has_many :offers
  has_many :publisher_conversions, :through => :apps
  has_many :advertiser_conversions, :through => :offers
  has_many :monthly_accountings
  
  validates_numericality_of :balance, :pending_earnings, :next_payout_amount, :only_integer => true, :allow_nil => false
  
  cattr_reader :per_page
  @@per_page = 20
  
  named_scope :to_calculate_next_payout_amount, :conditions => 'pending_earnings >= 10000'
  named_scope :to_payout, :conditions => 'pending_earnings != 0'
  named_scope :search, lambda { |name_or_email| { :joins => :users,
      :conditions => [ "partners.name LIKE ? OR users.email LIKE ?", "%#{name_or_email}%", "%#{name_or_email}%" ] }
    }
  
  def self.calculate_next_payout_amount(partner_id)
    Partner.using_slave_db do
      Partner.slave_connection.execute("BEGIN")
      partner = Partner.find(partner_id)
      return partner.pending_earnings - partner.publisher_conversions.created_since(partner.payout_cutoff_date).sum(:publisher_amount)
    end
  ensure
    Partner.using_slave_db do
      Partner.slave_connection.execute("COMMIT")
    end
  end
  
  def self.verify_balances(partner_id, alert_on_mismatch = false)
    Partner.using_slave_db do
      Partner.slave_connection.execute("BEGIN")
      partner = Partner.find(partner_id)
      partner.recalculate_balance_and_pending_earnings
      if alert_on_mismatch
        if partner.balance_changed?
          Notifier.alert_new_relic(BalancesMismatch, "Balance mismatch for partner: #{partner.id}, previously: #{partner.balance_was}, now: #{partner.balance}")
        end
        if partner.pending_earnings_changed?
          Notifier.alert_new_relic(BalancesMismatch, "Pending Earnings mismatch for partner: #{partner.id}, previously: #{partner.pending_earnings_was}, now: #{partner.pending_earnings}")
        end
      end
      return partner
    end
  ensure
    Partner.using_slave_db do
      Partner.slave_connection.execute("COMMIT")
    end
  end
  
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
  
  def reset_balances
    Partner.transaction do
      reload(:lock => 'FOR UPDATE')
      recalculate_balance_and_pending_earnings
      save!
    end
  end
  
  # This method will most likely not produce accurate sums unless
  # called from within some sort of transaction. See reset_balances
  # and Partner.verify_balances for examples.
  def recalculate_balance_and_pending_earnings
    orders_sum = orders.sum(:amount, :conditions => 'status = 1')
    payouts_sum = payouts.sum(:amount, :conditions => 'status = 1')
    publisher_conversions_sum = publisher_conversions.sum(:publisher_amount)
    advertiser_conversions_sum = advertiser_conversions.sum(:advertiser_amount)
    self.balance = orders_sum + advertiser_conversions_sum
    self.pending_earnings = publisher_conversions_sum - payouts_sum
  end
  
  def name_or_contact_name
    name.present? ? name : contact_name
  end

  def has_publisher_offer?
    offers.any?{|offer| offer.is_publisher_offer?}
  end
end
