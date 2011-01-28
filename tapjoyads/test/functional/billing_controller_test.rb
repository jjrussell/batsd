require 'test_helper'

class BillingControllerTest < ActionController::TestCase
  setup :activate_authlogic
  context "when creating create transfer" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user], :transfer_bonus => 0.1)
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    should "log transfer and math should work out" do
      @partner.transfer_bonus = 0.1
      @partner.save

      amount = rand(100) + 100
      bonus = (amount * @partner.transfer_bonus)

      get :create_transfer, { :transfer_amount => amount }
      @partner.reload

      assert_equal 2, @partner.orders.length
      assert_equal 1, @partner.payouts.length
      assert_equal 10000 - amount*100, @partner.pending_earnings
      assert_equal 10000 + amount*100 + bonus*100, @partner.balance

      assert_equal 3, assigns['activity_logs'].length
    end

    should "not allow negative transfer" do
      amount = rand(100) + 100
      negative_amount = -amount

      get :create_transfer, { :transfer_amount => negative_amount }

      @partner.reload

      #assert flash['error'].present?
      assert_equal 0, @partner.orders.length
      assert_equal 0, @partner.payouts.length
      assert_equal 10000, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      assert assigns['activity_logs'].nil?
    end

    should "not allow transfer greater than payout amount" do
      amount = rand(100) + 1000000

      get :create_transfer, { :transfer_amount => amount }

      @partner.reload

      #assert flash['error'].present?
      assert_equal 0, @partner.orders.length
      assert_equal 0, @partner.payouts.length
      assert_equal 10000, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      assert assigns['activity_logs'].nil?
    end

  end
end
