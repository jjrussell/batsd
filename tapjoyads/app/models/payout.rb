class Payout < ActiveRecord::Base
  include UuidPrimaryKey

  STATUS_CODES = { 0 => 'Invalid', 1 => 'Normal' }
  PAYMENT_METHODS = { 1 => 'Paid', 3 => 'Transfer' }

  belongs_to :partner

  validates_presence_of :partner
  validates_numericality_of :month, :only_integer => true, :allow_nil => false, :greater_than => 0, :less_than => 13
  validates_numericality_of :year, :only_integer => true, :allow_nil => false, :greater_than => 2007
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :payment_method, :in => PAYMENT_METHODS
  validates_inclusion_of :status, :in => STATUS_CODES

  after_create :update_balance

  named_scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }

  def <=> other
    created_at <=> other.created_at
  end

  def status_string
    STATUS_CODES[status]
  end

  def payment_method_string
    PAYMENT_METHODS[payment_method]
  end

  def is_transfer?; payment_method==3; end

  private

  def update_balance
    return true if amount == 0
    Partner.connection.execute("UPDATE partners SET pending_earnings = (pending_earnings - #{amount}), next_payout_amount = (next_payout_amount - #{amount}) WHERE id = '#{partner_id}'")
  end

end
