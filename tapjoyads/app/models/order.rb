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
  
  def <=> other
    created_at <=> other.created_at
  end
  
  def status_string
    case status
    when 0; "Invalid"
    when 1; "Normal"
    when 2; "Refund"
    end
  end

  def payment_method_string
    case payment_method
    when 0; "Website"
    when 1; "Invoice"
    when 2; "Bonus"
    when 3; "Transfer"
    end
  end
  def is_order?;    payment_method==0;  end
  def is_invoiced?; payment_method==1;  end
  def is_bonus?;    payment_method==2;  end
  def is_transfer?; payment_method==3;  end

private
  
  def update_balance
    return true if amount == 0
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{amount}) WHERE id = '#{partner_id}'")
  end
  
end
