require 'test_helper'

class MonthlyAccountingTest < ActiveSupport::TestCase
  subject { Factory(:monthly_accounting) }
  should belong_to(:partner)
  should validate_presence_of :partner
  should validate_numericality_of :month
  should validate_numericality_of :year

  context "MonthlyAccounting" do
    setup do
      @today = Date.today
      @now = Time.zone.now
      @monthly_accounting = Factory(:monthly_accounting)
    end

    context "with orders and payouts" do
      setup do
        @partner = @monthly_accounting.partner
        Factory(:order, :partner => @partner, :amount => 50)
        Factory(:payout, :partner => @partner, :amount => -51)
      end

      should "calculate totals" do
        @monthly_accounting.calculate_totals!
        assert_equal 50, @monthly_accounting.total_orders
        assert_equal 51, @monthly_accounting.total_payouts
      end
    end

    should "have start and end times" do
      assert_equal @now.beginning_of_month, @monthly_accounting.start_time
      assert_equal @now.end_of_month, @monthly_accounting.end_time
    end

    should "format dates" do
      assert_equal @today.beginning_of_month, @monthly_accounting.to_date
      assert_equal @today.beginning_of_month.strftime("%B %Y"), @monthly_accounting.to_mmm_yyyy
    end

    should "be ordered by dates" do
      ma_from_last_month = Factory(:monthly_accounting, :month => 1.month.ago(@today).month)

      assert_equal -1, ma_from_last_month <=> @monthly_accounting
      assert_equal  0, @monthly_accounting <=> @monthly_accounting
      assert_equal  1, @monthly_accounting <=> ma_from_last_month
    end

    should "calculate total orders" do
      orders = @monthly_accounting.website_orders + @monthly_accounting.invoiced_orders +
        @monthly_accounting.marketing_orders + @monthly_accounting.transfer_orders
      assert_equal orders, @monthly_accounting.total_orders
    end

    should "calculate total payouts" do
      payouts = @monthly_accounting.payment_payouts + @monthly_accounting.transfer_payouts
      assert_equal payouts, @monthly_accounting.total_payouts
    end

  end
end
