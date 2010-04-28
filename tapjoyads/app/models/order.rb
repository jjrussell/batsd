class Order < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :partner
  
  validates_presence_of :partner
  validates_inclusion_of :status, :payment_method, :in => [ 0, 1, 2 ]
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  
  after_create :update_balance
  
private
  
  def update_balance
    return true if self.amount == 0
    partner.balance += self.amount
    partner.save!
  end
  
end
