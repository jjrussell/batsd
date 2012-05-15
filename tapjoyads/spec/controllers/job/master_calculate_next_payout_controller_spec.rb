require 'spec/spec_helper'

describe Job::MasterCalculateNextPayoutController do
  before :each do
    @partner = Factory(:partner)
    @controller.expects(:authenticate).at_least_once.returns(true)
  end

  before :each do
    Partner.stubs(:to_calculate_next_payout_amount).returns([@partner])
    @partner.payout_threshold = 50_000_00
  end

  describe '#index' do
    context 'when confirmed for payout' do
      before :each do
        @partner.payout_threshold_confirmation = true
        @partner.save!
      end

      context 'when payout greater than threshold' do
        before :each do
          Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(50_000_01)
          get(:index)
          @partner.reload
        end

        it 'will unflag the partner' do
          @partner.payout_threshold_confirmation.should be_false
        end

        it 'will have a system note' do
          @partner.confirmation_notes.should include 'SYSTEM: Payout is greater than or equal to $50,000.00'
        end
      end

      context 'when payout less than threshold' do
        before :each do
          Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(40_000_01)
          get(:index)
          @partner.reload
        end

        it 'will not unflag partner on payout' do
          @partner.payout_threshold_confirmation.should be_true
        end

        it 'will not change the payout notes' do
          @partner.confirmation_notes.should_not include /SYSTEM: Payout is.*/
        end
      end
    end

    context 'when not confirmed for payout' do
      before :each do
        @partner.payout_threshold_confirmation = false
        @partner.save!
      end

      context 'when payout greater than threshold' do
        before :each do
          Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(50_000_01)
          get(:index)
          @partner.reload
        end

        it 'will not be confirmed' do
          @partner.payout_threshold_confirmation.should be_false
        end

        it 'will not have the system message' do
          @partner.confirmation_notes.should include 'SYSTEM: Payout is greater than or equal to $50,000.00'
        end
      end
    end

    context 'when payout greater than non-standard threshold' do
      before :each do
        @partner.payout_threshold_confirmation = true
        Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(65_000_01)
        @partner.payout_threshold = 65_000_00
        get(:index)
        @partner.reload
      end

      it 'will unflag the partner' do
        @partner.payout_threshold_confirmation.should be_false
      end

      it 'will have a system note' do
        @partner.confirmation_notes.should include 'SYSTEM: Payout is greater than or equal to $65,000.00'
      end
    end

    context 'when payout less than non-standard threshold' do
      before :each do
        Partner.stubs(:calculate_next_payout_amount).with(@partner.id).returns(55_000_01)
        @partner.payout_threshold = 65_000_00
        @partner.payout_threshold_confirmation = true
        @partner.save!
        get(:index)
        @partner.reload
      end

      it 'will not unflag the partner' do
        @partner.payout_threshold_confirmation.should be_true
      end

      it 'will not have a system note' do
        @partner.confirmation_notes.should_not include /SYSTEM: Payout is.*/
      end
    end
  end
end
