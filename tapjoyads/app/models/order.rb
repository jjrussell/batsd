class Order < ActiveRecord::Base
  include UuidPrimaryKey
  
  # Status Codes:
  # 0: promotional/marketing/unpaid
  # 1: normal/paid
  # 2: refund? we don't do this anymore
  
  belongs_to :partner
  
  validates_presence_of :partner
  validates_inclusion_of :status, :payment_method, :in => [ 0, 1, 2, 3 ]
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  
  after_create :update_balance
  
private
  
  def update_balance
    return true if amount == 0
    Partner.connection.execute("SELECT id FROM partners WHERE id = '#{partner_id}' FOR UPDATE")
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{amount}) WHERE id = '#{partner_id}'")
  end
  
end
