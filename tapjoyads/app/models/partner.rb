class Partner < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :orders
  has_many :payouts

  validates_presence_of :contact_name, :balance, :pending_earnings
  validates_numericality_of :balance, :pending_earnings, :only_integer => true, :allow_nil => false
end
