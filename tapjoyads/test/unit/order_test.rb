require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  subject { Factory(:order) }
  
  should belong_to(:partner)
  
  should validate_presence_of(:partner)
  should ensure_inclusion_of(:status).in_range(Order::STATUS_CODES)
  should ensure_inclusion_of(:payment_method).in_range(Order::PAYMENT_METHODS)
  should validate_numericality_of(:amount)
end
