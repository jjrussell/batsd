require 'spec_helper'

describe Reseller do
  describe '.has_many' do
    it { should have_many :users }
    it { should have_many :partners }
    it { should have_many :currencies }
    it { should have_many :offers }
  end

  describe '#valid?' do
    it { should validate_presence_of :name }
    it { should validate_numericality_of :rev_share }
    it { should validate_numericality_of :reseller_rev_share }
  end

  describe '.to_payout' do
    before :each do
      @reseller = FactoryGirl.create :reseller
      @pending  = 0
      @payout   = 0

      10.times do
        partner = FactoryGirl.create :partner,
          :reseller_id        => @reseller.id,
          :pending_earnings   => 1_000 + rand(1_000),
          :next_payout_amount => 1_000 + rand(1_000)

        @pending += partner.pending_earnings
        @payout  += partner.next_payout_amount
      end
    end

    let(:resellers) { Reseller.to_payout }
    let(:reseller) { resellers.first }

    it 'aggregates related partners pending_earnings' do
      reseller.pending_earnings.should == @pending
    end

    it 'aggregates related partners next_payout_amount' do
      reseller.next_payout_amount.should == @payout
    end
  end
end
