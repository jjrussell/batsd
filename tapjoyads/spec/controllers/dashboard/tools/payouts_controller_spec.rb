require 'spec_helper'

describe Dashboard::Tools::PayoutsController do
  render_views

  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:admin)
    @partner = FactoryGirl.create(:partner, :users => [@user])
    login_as(@user)
  end

  describe '#index' do
    it 'renders payouts page' do
      #TODO stub the 'all' method on the Arel query to reduce the number of partners passed in
      get(:index)
    end
  end

  describe '#confirm_payouts' do
    context 'when not admin, and not payout manager' do
      it 'does not succeed' do
        @user = FactoryGirl.create(:user)
        login_as(@user)
        post(:confirm_payouts, :partner_id => @partner.id)
        response.should_not be_success
      end
    end

    context 'when admin' do
      it 'succeeds' do
        post(:confirm_payouts, :partner_id => @partner.id)
        response.should be_success
      end
    end

    context 'when payout manager' do
      before :each do
        @user = FactoryGirl.create(:payout_manager)
        @partner = FactoryGirl.create(:partner, :users => [@user])
        login_as(@user)
        Partner.stub(:find).with(@partner.id).and_return(@partner)
      end

      context 'when partner is confirmed' do
        it 'succeeds' do
          @partner.stub(:confirm_for_payout).and_return(true)
          post(:confirm_payouts, :partner_id => @partner.id)
          response.should be_success
        end

        it 'confirms the partner' do
          @partner.should_receive(:confirm_for_payout).once
          post(:confirm_payouts, :partner_id => @partner.id)
        end
      end
    end
  end

  describe '#create' do
    context 'when a payout manager' do
      before :each do
        @user = FactoryGirl.create(:payout_manager)
        @partner = FactoryGirl.create(:partner, :users => [@user])
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
          payout = FactoryGirl.create(:payout, :partner => @partner)
          payout.stub(:persisted? => false, :save => false)
          @partner.stub(:make_payout).and_return(payout)
          Partner.stub(:find).with('faux').and_return(@partner)
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
      #TODO stub the 'all' method on the Arel query to reduce the number of partners passed in
      get(:export)
      response.header['Content-Type'].should include 'text/csv'
    end
  end
end
