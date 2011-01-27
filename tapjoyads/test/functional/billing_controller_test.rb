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

  end
end
