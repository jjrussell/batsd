require 'spec/spec_helper'

describe PayoutThresholdConfirmation do
  before :each do
    @payout_threshold_confirmation = Factory(:payout_threshold_confirmation)
  end

  describe '#after_confirm' do
    before :each do
      @partner = mock('partner')
      @payout_threshold_confirmation.stubs(:partner).returns(@partner)
    end

    it 'increases the payout threshold by 10%' do
      @partner.stubs(:next_payout_amount).returns(500)
      @partner.expects(:payout_threshold=).with(550).once
      @payout_threshold_confirmation.send(:after_confirm)
    end
  end

  describe '#get_system_notes' do
    before :each do
      @partner = mock('partner', :payout_threshold => 50_000_00)
      @payout_threshold_confirmation.stubs(:partner).returns(@partner)
    end

    it 'gives system note with proper threshold' do
      @payout_threshold_confirmation.send(:get_system_notes).should == 'SYSTEM: Payout is greater than or equal to $50,000.00'
    end
  end

  describe '#get_allowable_roles' do
    it 'has payout_manager, account_mgr, and admin' do
      @payout_threshold_confirmation.send(:get_allowable_roles).should == %w( payout_manager account_mgr admin)
    end
  end
end
