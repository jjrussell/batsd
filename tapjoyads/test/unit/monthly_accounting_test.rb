require 'test_helper'

class MonthlyAccountingTest < ActiveSupport::TestCase
  subject { Factory(:monthly_accounting) }

  context "Formatting dates" do
    setup do
      @today = Date.today
      @monthly_accounting = Factory(:monthly_accounting)
      @ma_from_last_month = Factory(:monthly_accounting, :month => 1.month.ago(@today).month)
    end

    should "format dates" do
      assert_equal @today.beginning_of_month, @monthly_accounting.to_date
      assert_equal @today.beginning_of_month.strftime("%B %Y"), @monthly_accounting.to_mmm_yyyy
    end

    should "compare by dates" do
      assert_equal -1, @ma_from_last_month <=> @monthly_accounting
      assert_equal  0, @monthly_accounting <=> @monthly_accounting
      assert_equal  1, @monthly_accounting <=> @ma_from_last_month
    end

  end

  context "Summary balances" do
    setup do
      @today = Date.today
      @monthly_accounting = Factory(:monthly_accounting)
    end

    should "calculate total orders" do
      orders = @monthly_accounting.website_orders + @monthly_accounting.invoiced_orders +
        @monthly_accounting.marketing_orders + @monthly_accounting.transfer_orders
      assert_equal orders, @monthly_accounting.orders
    end

    should "calculate total payouts" do
      payouts = @monthly_accounting.payment_payouts + @monthly_accounting.transfer_payouts
      assert_equal payouts, @monthly_accounting.payouts
    end

  end
end
