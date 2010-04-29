class Order < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :partner
  
  validates_presence_of :partner
  validates_inclusion_of :status, :payment_method, :in => [ 0, 1, 2 ]
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  
  after_create :update_balance
  after_update :this_will_be_deleted
  
private
  
  def update_balance
    return true if self.amount == 0
    partner.balance += self.amount
    partner.save!
  end
  
  def this_will_be_deleted
    return true unless self.amount_changed?
    partner.balance -= self.amount_was
    partner.balance += self.amount
    partner.save!
  end
  
end
