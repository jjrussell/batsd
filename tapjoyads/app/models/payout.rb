class Payout < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :partner

  validates_presence_of :amount, :month, :year
  validates_numericality_of :month, :only_integer => true, :allow_nil => false, :greater_than => 0, :less_than => 13
  validates_numericality_of :year, :only_integer => true, :allow_nil => false, :greater_than => 2007
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
end
