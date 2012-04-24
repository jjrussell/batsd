require 'spec_helper'

describe PayoutConfirmation do
  it 'associates' do
    should belong_to(:partner)
  end

  before :each do
    @partner = Partner.new(:name => 'blah')
    @partner.save
    @payout_confirmation = Factory(:payout_threshold_confirmation)
  end

  describe '#confirm' do
    before :each do
      @payout_confirmation.stubs(:respond_to?).with(:after_confirm).returns(false)
    end

    it 'sets confirmed to true' do
      @payout_confirmation.expects(:confirmed=).with(true).once
      @payout_confirmation.confirm
    end

    context 'when after_confirm method not present' do
      it 'does nothing' do
        @payout_confirmation.expects(:after_confirm).never
        @payout_confirmation.confirm
      end
    end

    context 'when after_confirm method is present' do
      before :each do
        @payout_confirmation.stubs(:respond_to?).with(:after_confirm).returns(true)
      end
      it 'calls after_confirm' do
        @payout_confirmation.expects(:after_confirm).once
        @payout_confirmation.confirm
      end
    end
  end

  describe '#unconfirm' do
    it 'sets confirmed to false' do
      @payout_confirmation.expects(:confirmed=).with(false).once
      @payout_confirmation.unconfirm
    end
  end

  describe '#system_notes' do
    before :each do
      @payout_confirmation.stubs(:get_system_notes).returns('blowed up')
    end
    context 'when confirmed is true' do
      it 'returns nil' do
        @payout_confirmation.system_notes.should be_nil
      end
    end

    context 'when confirmed is false' do
      before :each do
        @payout_confirmation.stubs(:confirmed).returns(false)
      end

      it 'returns notes' do
        @payout_confirmation.system_notes.should == 'blowed up'
      end
    end
  end

  describe '#has_proper_role' do
    before :each do
      @payout_confirmation.stubs(:get_allowable_roles).returns(%w(admin))
    end

    context 'when user is admin' do
      before :each do
        @user = Factory(:admin)
      end

      it 'returns true' do
        @payout_confirmation.has_proper_role(@user).should be_true
      end
    end

    context 'when user is agency user' do
      before :each do
        @user = Factory(:agency_user)
      end

      it 'returns false' do
        @payout_confirmation.has_proper_role(@user).should be_false
      end
    end
  end
end
