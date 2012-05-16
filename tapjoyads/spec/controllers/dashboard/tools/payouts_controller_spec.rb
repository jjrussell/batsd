require 'spec_helper'

describe Dashboard::Tools::PayoutsController do
  render_views

  before :each do
    activate_authlogic
    @user = Factory(:admin)
    @partner = Factory(:partner, :users => [@user])
    login_as(@user)
  end

  describe '#index' do
    it 'renders payouts page' do
      get(:index)
    end
  end

  describe '#confirm_payouts' do
    context 'when not payout manager' do
      it 'does not succeed' do
        post(:confirm_payouts, :id => @partner.id)
        response.should_not be_success
      end
    end

    context 'when payout manager' do
      before :each do
        @user = Factory(:payout_manager_user)
        @partner = Factory(:partner, :users => [@user])
        login_as(@user)
        Partner.stubs(:find).with(@partner.id).returns(@partner)
      end

      context 'when partner is confirmed' do
        it 'succeeds' do
          @partner.stubs(:confirm_for_payout).returns(true)
          post(:confirm_payouts, :partner_id => @partner.id)
          response.should be_success
        end

        it 'confirms the partner' do
          @partner.expects(:confirm_for_payout).once
          post(:confirm_payouts, :partner_id => @partner.id)
        end
      end
    end
  end

  describe '#create' do
    context 'when a payout manager' do
      before :each do
        @user = Factory(:payout_manager_user)
        @partner = Factory(:partner, :users => [@user])
        login_as(@user)
      end

      it 'will create a payout' do
        post(:create, :partner_id => @partner.id, :amount => '1.00')
        response.body.should == {:success => true}.to_json
      end

      context 'when calculated payout threshold is greater than 50k' do
        it 'increases the threshold' do
          post(:create, :partner_id => @partner.id, :amount => '49001.00')
          @partner.reload
          @partner.payout_threshold.should == (49_001_00 * 1.2)
        end
      end

      context 'when payout not saved properly' do
        before :each do
          payout = Factory(:payout, :partner => @partner)
          payout.stubs(:save).returns(false)
          payouts = mock('build',:build => payout)
          @partner.stubs(:payouts).returns(payouts)
          Partner.stubs(:find).with('faux').returns(@partner)
        end

        it 'will fail' do
          post(:create, :partner_id => 'faux', :amount => '1.00')
          response.body.should == {:success => false}.to_json
        end
      end
    end
  end

  describe '#export' do
    it 'sends a csv report' do
      Partner.stubs(:to_payout).returns(stub('payout partners', :all => [Factory(:partner, :users => [@user])]))
      get(:export)
      response.header['Content-Type'].should include 'text/csv'
    end
  end
end
