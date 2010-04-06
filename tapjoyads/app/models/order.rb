class Order < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  validates_presence_of :partner, :status, :payment_method, :amount
  validates_inclusion_of :status, :payment_method, :in => [ 0, 1, 2 ]
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
end
