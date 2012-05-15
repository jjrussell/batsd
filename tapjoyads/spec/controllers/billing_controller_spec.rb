require 'spec/spec_helper'

describe BillingController do
  before :each do
    activate_authlogic
    user = Factory(:user)
    @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [user], :transfer_bonus => 0.1)
    login_as(user)
  end

  describe 'admins creating transfers' do
    it 'logs transfer and math works out' do
      get(:create_transfer, { :transfer_amount => '$1.00' })
      @partner.reload

      @partner.orders.length.should == 2
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 9_900
      @partner.balance.should == 10_110
    end

    it 'does not allow negative transfer' do
      get(:create_transfer, { :transfer_amount => '$-1.00' })
      @partner.reload

      @partner.orders.should be_blank
      @partner.payouts.should be_blank
      @partner.pending_earnings.should == 10_000
      @partner.balance.should == 10_000
    end

    it 'does not allow transfer greater than pending_earnings amount' do
      get(:create_transfer, { :transfer_amount => '$100.01' })
      @partner.reload

      @partner.orders.should be_blank
      @partner.payouts.should be_blank
      @partner.pending_earnings.should == 10_000
      @partner.balance.should == 10_000
    end
  end

  describe '#update_payout_info' do
    before :each do
      @payout_info = Factory(:payout_info, :partner => @partner)
      @partner.payout_info_confirmation = true
      @partner.save!
      @partner.payout_info.stubs(:safe_update_attributes).returns(true)
      post(:update_payout_info, :payout_info => {})
      @partner.reload
    end

    context 'when payouts are already confirmed for the partner' do
      it 'unconfirms payouts' do
        @partner.payout_info_confirmation.should be_false
      end

      it 'adds a system not that the payout info changed' do
        @partner.confirmation_notes.should include 'SYSTEM: Partner Payout Information has changed.'
      end
    end
  end
end
