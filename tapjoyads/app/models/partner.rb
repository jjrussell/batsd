class Partner < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :orders
  has_many :payouts
  has_many :users

  validates_presence_of :balance, :pending_earnings
  validates_numericality_of :balance, :pending_earnings, :only_integer => true, :allow_nil => false
  
  cattr_reader :per_page
  @@per_page = 20
end
