class Order < ActiveRecord::Base
  include UuidPrimaryKey
  
  STATUS_CODES = [ 0, 1, 2 ]
  # 0: invalid
  # 1: normal/paid
  # 2: refunds
  PAYMENT_METHODS = [ 0, 1, 2, 3 ]
  # 0: website
  # 1: freshbooks/billable/invoice
  # 2: marketing expense
  # 3: transfer
  
  belongs_to :partner
  
  validates_presence_of :partner
  validates_inclusion_of :status, :in => STATUS_CODES
  validates_inclusion_of :payment_method, :in => PAYMENT_METHODS
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  
  after_create :update_balance
  
private
  
  def update_balance
    return true if amount == 0
    Partner.connection.execute("SELECT id FROM partners WHERE id = '#{partner_id}' FOR UPDATE")
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{amount}) WHERE id = '#{partner_id}'")
  end
  
end
