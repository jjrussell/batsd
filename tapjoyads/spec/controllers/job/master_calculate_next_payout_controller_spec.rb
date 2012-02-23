require 'spec/spec_helper'

describe Job::MasterCalculateNextPayoutController do
  before :each do
    @partner = Factory(:partner)
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  describe '#index' do
    it 'should unflag partner on payout greater than $50,000' do
      @partner.confirmed_for_payout = true
      @partner.save!
      @partner.confirmed_for_payout.should be_true
      Partner.stubs(:to_calculate_next_payout_amount).returns([@partner])
      Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(50_000_01)
      get(:index)
      @partner.reload
      @partner.confirmed_for_payout.should_not be_true
      @partner.payout_confirmation_notes.should == 'SYSTEM: Payout is greater than or equal to $50,000.00'
    end

    it 'should not unflag partner on payout less than $50,000' do
      @partner.confirmed_for_payout = true
      @partner.save!
      @partner.confirmed_for_payout.should be_true
      Partner.stubs(:to_calculate_next_payout_amount).returns([@partner])
      Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(40_000_01)
      get(:index)
      @partner.reload
      @partner.confirmed_for_payout.should be_true
      @partner.payout_confirmation_notes.should be_nil
    end
  end
end
