class Payout < ActiveRecord::Base
  include UuidPrimaryKey

  STATUS_CODES = [ 0, 1 ]
  # 0: invalid
  # 1: normal
  PAYMENT_METHODS = [ 1, 3 ]
  # 1: paid
  # 3: transfer

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
    case status
    when 0; "Invalid"
    when 1; "Normal"
    end
  end

  def payment_method_string
    case payment_method
    when 1; "Paid"
    when 3; "Transfer"
    end
  end
  def is_transfer?; payment_method==3; end

private

  def update_balance
    return true if amount == 0
    Partner.connection.execute("UPDATE partners SET pending_earnings = (pending_earnings - #{amount}), next_payout_amount = (next_payout_amount - #{amount}) WHERE id = '#{partner_id}'")
  end

end
