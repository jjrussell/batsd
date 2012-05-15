require 'spec_helper'

describe Payout do
  subject { Factory(:payout) }

  describe '.belongs_to' do
    it { should belong_to(:partner) }
  end

  describe '#valid?' do
    it { should validate_presence_of(:partner) }
    it { should validate_numericality_of(:month) }
    it { should validate_numericality_of(:year) }
    it { should validate_numericality_of(:amount) }
    it { should ensure_inclusion_of(:payment_method).in_range(Payout::PAYMENT_METHODS.keys) }
    it { should ensure_inclusion_of(:status).in_range(Payout::STATUS_CODES.keys) }
  end

  context "A Payout" do
    before :each do
      @partner = Factory(:partner, :pending_earnings => 100)
    end

    it "decreases a partner's pending earnings" do
      @partner.pending_earnings.should == 100
      @partner.payouts.count.should == 0
      Factory(:payout, :partner => @partner, :amount => 100)
      @partner.reload
      @partner.pending_earnings.should == 0
      @partner.payouts.count.should == 1
    end
  end

  describe '#status_string' do
    before :each do
      @payout = Factory(:payout)
    end

    context 'when status is invalid' do
      it 'returns the string "Invalid"' do
        @payout.status = 0
        @payout.status_string.should == 'Invalid'
      end
    end

    context 'when status is normal' do
      it 'returns the string "Normal"' do
        @payout.status = 1
        @payout.status_string.should == 'Normal'
      end
    end
  end

  describe '#payment_method_string' do
    before :each do
      @payout = Factory(:payout)
    end

    context 'when payment method is paid' do
      it 'returns the string "Paid"' do
        @payout.payment_method = 1
        @payout.payment_method_string.should == 'Paid'
      end
    end

    context 'when payment method is transfer' do
      it 'returns the string "Transfer"' do
        @payout.payment_method = 3
        @payout.payment_method_string.should == 'Transfer'
      end
    end
  end
end
