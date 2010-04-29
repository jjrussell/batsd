class Payout < ActiveRecord::Base
  include UuidPrimaryKey
  
  belongs_to :partner
  
  validates_presence_of :partner
  validates_numericality_of :month, :only_integer => true, :allow_nil => false, :greater_than => 0, :less_than => 13
  validates_numericality_of :year, :only_integer => true, :allow_nil => false, :greater_than => 2007
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  validates_inclusion_of :status, :in => [ 0, 1 ]
  
  after_create :update_balance
  
private
  
  def update_balance
    return true if self.amount == 0
    partner.pending_earnings -= self.amount
    partner.next_payout_amount = 0
    partner.save!
  end
  
end
