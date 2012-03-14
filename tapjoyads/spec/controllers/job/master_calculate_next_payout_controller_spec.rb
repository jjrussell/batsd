require 'spec/spec_helper'

describe Job::MasterCalculateNextPayoutController do
  before :each do
    @partner = Factory(:partner)
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  describe '#index' do
    before :each do
      Partner.stubs(:to_calculate_next_payout_amount).returns([@partner])
    end

    context 'when confirmed for payout' do
      before :each do
        @partner.confirmed_for_payout = true
        @partner.save!
      end

      context 'when payout greater than $50,000' do
        before :each do
          Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(50_000_01)
          get(:index)
          @partner.reload
        end

        it 'will unflag the partner' do
          @partner.confirmed_for_payout.should be_false
        end

        it 'will have a system note' do
          @partner.payout_confirmation_notes.should == 'SYSTEM: Payout is greater than or equal to $50,000.00'
        end
      end

      context 'when payout less than $50,000' do
        before :each do
          Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(40_000_01)
          get(:index)
          @partner.reload
        end

        it 'will not unflag partner on payout' do
          @partner.confirmed_for_payout.should be_true
        end

        it 'will not change the payout notes' do
          @partner.payout_confirmation_notes.should be_nil
        end
      end
    end

    context 'when not confirmed for payout' do
      before :each do
        @partner.confirmed_for_payout = false
        @partner.payout_confirmation_notes = 'should stick!'
        @partner.save!
      end

      context 'when payout greater than $50,000' do
        before :each do
          Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(50_000_01)
          get(:index)
          @partner.reload
        end

        it 'will not be confirmed' do
          @partner.confirmed_for_payout.should be_false
        end

        it 'will not have the system message' do
          @partner.payout_confirmation_notes.should_not == 'SYSTEM: Payout is greater than or equal to $50,000.00'
        end
      end
    end
  end
end
