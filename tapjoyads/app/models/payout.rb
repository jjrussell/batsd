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

  def <=> other
    [year, month] <=> [other.year, other.month]
  end

private
  
  def update_balance
    return true if amount == 0
    Partner.connection.execute("SELECT id FROM partners WHERE id = '#{partner_id}' FOR UPDATE")
    Partner.connection.execute("UPDATE partners SET pending_earnings = (pending_earnings - #{amount}), next_payout_amount = (next_payout_amount - #{amount}) WHERE id = '#{partner_id}'")
  end
  
end
