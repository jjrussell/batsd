require 'spec_helper'

describe Dashboard::BillingController do
  let(:user)    { FactoryGirl.create(:user) }
  let(:partner) { FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [user], :transfer_bonus => 0.1) }

  before :each do
    activate_authlogic
    login_as(user)
    controller.stub(:current_user).and_return(user)
    controller.stub(:current_partner).and_return(partner)
  end

  describe 'admins creating transfers' do
    it 'logs transfer and math works out' do
      get(:create_transfer, { :transfer_amount => '$1.00' })
      partner.reload

      partner.orders.length.should == 2
      partner.payouts.length.should == 1
      partner.pending_earnings.should == 9_900
      partner.balance.should == 10_110
    end

    it 'does not allow negative transfer' do
      get(:create_transfer, { :transfer_amount => '$-1.00' })
      partner.reload

      partner.orders.should be_blank
      partner.payouts.should be_blank
      partner.pending_earnings.should == 10_000
      partner.balance.should == 10_000
    end

    it 'does not allow transfer greater than pending_earnings amount' do
      get(:create_transfer, { :transfer_amount => '$100.01' })
      partner.reload

      partner.orders.should be_blank
      partner.payouts.should be_blank
      partner.pending_earnings.should == 10_000
      partner.balance.should == 10_000
    end
  end

  describe '#update_payout_info' do
    let(:payout_info) do
      info = FactoryGirl.create(:payout_info, :partner => partner)
      partner.payout_info_confirmation = true
      partner.stub(:payout_info).and_return(info)
      partner.save
      info
    end

    let(:params) do
      {
          :tax_id           => '12341234',
          :billing_name     => "Some new billing name",
          :beneficiary_name => "Some new billing name",
          :address_1        => "101 Awesome St."
      }
    end

    before(:each) { partner.reload }

    context 'given a user who is not a Tapjoy employee' do
      before(:each) { user.stub(:employee?).and_return(false) }

      it 'cannot change the tax ID' do
        expect{
          post(:update_payout_info, :payout_info => params)
          payout_info.reload
        }.not_to change{payout_info.decrypt_tax_id}
      end

      it 'cannot change the billing name' do
        expect do
          post(:update_payout_info, :payout_info => params)
          payout_info.reload
        end.not_to change{payout_info.billing_name}
      end
    end

    context 'given a user who is a Tapjoy employee' do
      before(:each) { user.stub(:employee?).and_return(true) }

      it 'can change the tax ID' do
        expect{
          post(:update_payout_info, :payout_info => params)
          payout_info.reload
        }.to change{payout_info.decrypt_tax_id}
      end

      it 'can change the billing name' do
        expect{
          post(:update_payout_info, :payout_info => params)
          payout_info.reload
        }.to change{payout_info.billing_name}
      end
    end

    context 'when payouts are already confirmed for the partner' do
      context 'on a success' do
        before(:each) do
          payout_info.stub(:safe_update_attributes).and_return(true)
          post(:update_payout_info, :payout_info => {})
          partner.reload
        end
        it 'unconfirms payouts' do
          partner.payout_info_confirmation.should be_false
        end

        it 'adds a system note that the payout info changed' do
          partner.confirmation_notes.any? {|m| m =~ /Partner Payout Information has changed/}.should be_true
        end
      end
    end

  end
end
