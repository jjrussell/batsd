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
      get :create_transfer, { :transfer_amount => '$1.00' }
      @partner.reload

      @partner.orders.length.should == 2
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 9_900
      @partner.balance.should == 10_110
    end

    it 'does not allow negative transfer' do
      get :create_transfer, { :transfer_amount => '$-1.00' }
      @partner.reload

      @partner.orders.should be_blank
      @partner.payouts.should be_blank
      @partner.pending_earnings.should == 10_000
      @partner.balance.should == 10_000
    end

    it 'does not allow transfer greater than pending_earnings amount' do
      get :create_transfer, { :transfer_amount => '$100.01' }
      @partner.reload

      @partner.orders.should be_blank
      @partner.payouts.should be_blank
      @partner.pending_earnings.should == 10_000
      @partner.balance.should == 10_000
    end
  end

  describe 'updating payout info' do
    it 'should unconfirm for payouts if already confirmed' do
      @payout_info = Factory(:payout_info, :partner => @partner)
      @partner.confirmed_for_payout = true
      @partner.save
      @partner.confirmed_for_payout.should be_true
      @partner.payout_info.stubs(:safe_update_attributes).returns(true)

      post :update_payout_info, { :payout_info => {} }
      @partner.reload
      @partner.confirmed_for_payout.should_not be_true
      @partner.payout_confirmation_notes.should == "SYSTEM: Partner Payout Information has changed."
    end
  end
end
