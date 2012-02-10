require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  subject { Factory(:order) }

  should belong_to(:partner)

  should validate_presence_of(:partner)
  should ensure_inclusion_of(:status).in_range(Order::STATUS_CODES.keys)
  should ensure_inclusion_of(:payment_method).in_range(Order::PAYMENT_METHODS.keys)
  should validate_numericality_of(:amount)

  context "An Order" do
    setup do
      @partner = Factory(:partner)
    end

    should "increase a partner's balance" do
      assert_equal 0, @partner.balance
      assert_equal 0, @partner.orders.count
      Factory(:order, :partner => @partner, :amount => 100, :note => 'note')
      @partner.reload
      assert_equal 100, @partner.balance
      assert_equal 1, @partner.orders.count
    end
  end
end
