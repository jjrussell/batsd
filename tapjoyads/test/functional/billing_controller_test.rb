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
      get :create_transfer, { :transfer_amount => '$1.00' }
      @partner.reload

      assert_equal 2, @partner.orders.length
      assert_equal 1, @partner.payouts.length
      assert_equal 9900, @partner.pending_earnings
      assert_equal 10110, @partner.balance

      assert_equal 3, assigns['activity_logs'].length
    end

    should "not allow negative transfer" do
      get :create_transfer, { :transfer_amount => '$-1.00' }
      @partner.reload

      assert_equal 0, @partner.orders.length
      assert_equal 0, @partner.payouts.length
      assert_equal 10000, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      assert assigns['activity_logs'].nil?
    end

    should "not allow transfer greater than pending_earnings amount" do
      get :create_transfer, { :transfer_amount => '$100.01' }
      @partner.reload

      assert_equal 0, @partner.orders.length
      assert_equal 0, @partner.payouts.length
      assert_equal 10000, @partner.pending_earnings
      assert_equal 10000, @partner.balance
      assert assigns['activity_logs'].nil?
    end

  end
end
