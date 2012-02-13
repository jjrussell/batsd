require 'spec_helper'

describe MonthlyAccounting do
  subject { Factory(:monthly_accounting) }
  describe '.belongs_to' do
    it { should belong_to(:partner) }
  end

  describe '#valid?' do
    it { should validate_presence_of :partner }
    it { should validate_numericality_of :month }
    it { should validate_numericality_of :year }
  end

  context 'MonthlyAccounting' do
    before :each do
      @today = Time.zone.today
      @now = Time.zone.now
      @monthly_accounting = Factory(:monthly_accounting)
    end

    context 'with orders and payouts' do
      before :each do
        @partner = @monthly_accounting.partner
        Factory(:order, :partner => @partner, :amount => 50)
        Factory(:payout, :partner => @partner, :amount => -51)
      end

      it 'calculates totals' do
        @monthly_accounting.calculate_totals!
        @monthly_accounting.total_orders.should == 50
        @monthly_accounting.total_payouts.should == 51
      end
    end

    it 'has start and end times' do
      @monthly_accounting.start_time.should == @now.beginning_of_month
      @monthly_accounting.end_time.should == @now.beginning_of_month.next_month
    end

    it 'formats dates' do
      @monthly_accounting.to_date.should == @today.beginning_of_month
      @monthly_accounting.to_mmm_yyyy.should == @today.beginning_of_month.strftime('%B %Y')
    end

    it 'is ordered by dates' do
      ma_from_last_month = Factory(:monthly_accounting, :month => 1.month.ago(@today).month, :year => 1.year.ago(@today).year)

      (ma_from_last_month <=> @monthly_accounting).should == -1
      (@monthly_accounting <=> @monthly_accounting).should ==  0
      (@monthly_accounting <=> ma_from_last_month).should ==  1
    end

    it 'calculates total orders' do
      orders = @monthly_accounting.website_orders + @monthly_accounting.invoiced_orders +
        @monthly_accounting.marketing_orders + @monthly_accounting.transfer_orders
      @monthly_accounting.total_orders.should == orders
    end

    it 'calculates total payouts' do
      payouts = @monthly_accounting.payment_payouts + @monthly_accounting.transfer_payouts
      @monthly_accounting.total_payouts.should == payouts
    end

  end
end
