class Partner < ActiveRecord::Base
  include UuidPrimaryKey
  
  has_many :orders
  has_many :payouts
  has_many :partner_assignments
  has_many :users, :through => :partner_assignments
  has_many :apps
  has_many :email_offers
  has_many :offers
  
  validates_numericality_of :balance, :pending_earnings, :only_integer => true, :allow_nil => false
  
  cattr_reader :per_page
  @@per_page = 20
end
