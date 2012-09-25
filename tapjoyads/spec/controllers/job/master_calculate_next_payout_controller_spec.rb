require 'spec_helper'

describe Job::MasterCalculateNextPayoutController do
  before :each do
    @partner = FactoryGirl.create(:partner)
    @controller.should_receive(:authenticate).at_least(:once).and_return(true)
  end

  describe '#index' do
    before :each do
      Partner.stub(:to_calculate_next_payout_amount).and_return([@partner])
      @partner.payout_threshold = 50_000_00
    end

    context 'when confirmed for payout' do
      before :each do
        @partner.payout_threshold_confirmation = true
        @partner.save!
      end

      context 'when payout greater than threshold' do
        before :each do
          Partner.stub(:calculate_next_payout_amount).with(@partner.id).and_return(50_000_01)
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
          Partner.stub(:calculate_next_payout_amount).with(@partner.id).and_return(40_000_01)
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
          Partner.stub(:calculate_next_payout_amount).with(@partner.id).and_return(50_000_01)
          get(:index)
          @partner.reload
        end

        it 'will not be confirmed' do
          @partner.payout_threshold_confirmation.should be_false
        end

        it 'will have a system message' do
          @partner.confirmation_notes.should include 'SYSTEM: Payout is greater than or equal to $50,000.00'
        end
      end
    end

    context 'when payout greater than non-standard threshold' do
      before :each do
        @partner.payout_threshold_confirmation = true
        Partner.stub(:calculate_next_payout_amount).with(@partner.id).and_return(65_000_01)
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
        Partner.stub(:calculate_next_payout_amount).with(@partner.id).and_return(55_000_01)
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

  context 'with failures' do
    before :each do
      @partners = []
      10.times { @partners << FactoryGirl.create(:partner) }
      Partner.stub(:to_calculate_next_payout_amount).and_return(@partners)
      Partner.stub(:calculate_next_payout_amount).and_return(100)
    end

    it 'completes with a small percentage of errors' do
      @partners[4].stub(:save!).and_raise('Test exception')
      get(:index)
    end

    it 'fails with a larger percentage of errors' do
      @partners[2].stub(:save!).and_raise('Test exception')
      @partners[7].stub(:save!).and_raise('Test exception 2')
      lambda { get(:index) }.should raise_exception
    end
  end
end
