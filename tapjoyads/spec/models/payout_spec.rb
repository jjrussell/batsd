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
    it { should ensure_inclusion_of(:payment_method).in_range(Payout::PAYMENT_METHODS) }
    it { should ensure_inclusion_of(:status).in_range(Payout::STATUS_CODES) }
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
end
