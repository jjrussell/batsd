require 'test_helper'

class PayoutTest < ActiveSupport::TestCase
  subject { Factory(:payout) }
  
  should belong_to(:partner)
  
  should validate_presence_of(:partner)
  should validate_numericality_of(:month)
  should validate_numericality_of(:year)
  should validate_numericality_of(:amount)
  should ensure_inclusion_of(:payment_method).in_range(Payout::PAYMENT_METHODS)
  should ensure_inclusion_of(:status).in_range(Payout::STATUS_CODES)
end
