require 'test_helper'

class ResellerTest < ActiveSupport::TestCase
  should have_many :users
  should have_many :partners
  should have_many :currencies
  should have_many :offers

  should validate_presence_of :name
  should validate_numericality_of :rev_share
  should validate_numericality_of :reseller_rev_share
end
