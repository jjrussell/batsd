require 'spec/spec_helper'

describe Tools::PartnerValidationsController do
  integrate_views

  before :each do
    activate_authlogic
    fake_the_web
    @user = Factory(:admin)
    @partner = Factory(:partner, :users => [@user])
    login_as(@user)
  end

  describe '#index' do
    it 'renders the validations page' do
      get(:index)
    end
  end

  describe '#confirm_payouts' do
    before :each do
      @controller.stubs(:set_recent_partners)
    end

    context 'when not payout manager' do
      before :each do
        @partner = Factory(:partner, :users => [@user])
        @user = Factory(:payout_manager_user)
        login_as(@user)
        Partner.stubs(:find).with(@partner.id).returns(@partner)
      end

      it 'does not succeed' do
        get(:confirm_payouts, :partner_id => @partner.id)
        response.should_not be_success
      end
    end

    context 'when admin' do
      before :each do
        @partner = Factory(:partner, :users => [@user])
        login_as(@user)
        Partner.stubs(:find).with(@partner.id).returns(@partner)
        @controller.stubs(:log_activity)
      end

      context 'when partner is confirmed' do
        it 'succeeds' do
          @partner.stubs(:confirm_for_payout).returns(true)
          get(:confirm_payouts, :partner_id => @partner.id)
          response.should be_success
        end

        it 'confirms the partner' do
          @partner.expects(:confirm_for_payout).once
          get(:confirm_payouts, :partner_id => @partner.id)
        end
      end
    end
  end
end
