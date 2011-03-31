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
    end

    should "not allow negative transfer" do
      get :create_transfer, { :transfer_amount => '$-1.00' }
      @partner.reload

      assert_equal 0, @partner.orders.length
      assert_equal 0, @partner.payouts.length
      assert_equal 10000, @partner.pending_earnings
      assert_equal 10000, @partner.balance
    end

    should "not allow transfer greater than pending_earnings amount" do
      get :create_transfer, { :transfer_amount => '$100.01' }
      @partner.reload

      assert_equal 0, @partner.orders.length
      assert_equal 0, @partner.payouts.length
      assert_equal 10000, @partner.pending_earnings
      assert_equal 10000, @partner.balance
    end

  end

  context "when storing credit cards" do
    setup do
      @user = Factory(:user)
      @partner = Factory(:partner, :users => [@user])
      cc_params    = {
        :first_name => 'bar',
        :last_name => 'foo',
        :number => '4111111111111111',
        :verification_value => '999',
        :month => '1',
        :year => '2020',
        :amount => '500',
      }
      @credit_card = ActiveMerchant::Billing::CreditCardWithAmount.new(cc_params)

      Billing.create_customer_profile(@user)
      Billing.create_payment_profile(@user, @credit_card)
      @payment_profiles = Billing.get_payment_profiles_for_select(@user)

      login_as(@user)
    end

    should "be able to forget credit cards" do
      profile = @payment_profiles.reject{|profile| profile[1] == 'new_card'}.first
      assert_equal 2, Billing.get_payment_profiles_for_select(@user).length
      post :forget_credit_card, :payment_profile_id => profile[1]
      assert_equal 1, Billing.get_payment_profiles_for_select(@user).length
    end
  end
end
