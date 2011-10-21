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

  context "A Payout" do
    setup do
      @partner = Factory(:partner, :pending_earnings => 100)
    end

    should "decrease a partner's pending earnings" do
      assert_equal 100, @partner.pending_earnings
      assert_equal 0, @partner.payouts.count
      Factory(:payout, :partner => @partner, :amount => 100)
      @partner.reload
      assert_equal 0, @partner.pending_earnings
      assert_equal 1, @partner.payouts.count
    end
  end
end
