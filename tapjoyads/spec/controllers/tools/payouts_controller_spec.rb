require 'spec/spec_helper'

describe Tools::PayoutsController do
  include Authlogic::TestCase

  render_views

  before :each do
    activate_authlogic
  end

  describe '#index' do
    before :each do
      @user = Factory(:admin)
      @partner = Factory(:partner, :users => [@user])
      login_as(@user)
    end

    it 'renders payouts page' do
      get(:index)
    end
  end

  describe '#confirm_payouts' do
    context 'when not payout manager' do
      before :each do
        @user = Factory(:admin)
        @partner = Factory(:partner, :users => [@user])
        login_as(@user)
        post(:confirm_payouts, :id => @partner.id)
      end

      it 'does not succeed' do
        response.should_not be_success
      end
    end

    context 'when payout manager' do
      before :each do
        @user = Factory(:payout_manager_user)
        @partner = Factory(:partner, :users => [@user])
        login_as(@user)
      end

      context 'when partner is confirmed' do
        before :each do
          @partner.confirmed_for_payout = true
          @partner.save
          post(:confirm_payouts, :partner_id => @partner.id)
          @partner.reload
        end

        it 'succeeds' do
          response.should be_success
        end

        it 'unconfirms the partner' do
          @partner.confirmed_for_payout.should be_false
        end
      end

      context 'when partner is confirmed' do
        before :each do
          @partner.confirmed_for_payout = false
          @partner.save
          post(:confirm_payouts, :partner_id => @partner.id)
          @partner.reload
        end

        it 'succeeds' do
          response.should be_success
        end

        it 'confirms the partner' do
          @partner.confirmed_for_payout.should be_true
        end
      end
    end
  end
end
