require 'spec/spec_helper'

describe PayoutInfoConfirmation do
  before :each do
    @payout_info_confirmation = Factory(:payout_info_confirmation)
  end

  describe '#get_system_notes' do
    it 'gives proper system note' do
      @payout_info_confirmation.send(:get_system_notes).should == 'SYSTEM: Partner Payout Information has changed.'
    end
  end

  describe '#get_allowable_roles' do
    it 'gives a list containing payout_manager' do
      @payout_info_confirmation.send(:get_allowable_roles).should == ['payout_manager']
    end
  end
end
