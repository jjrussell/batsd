require 'spec_helper'

describe Dashboard::Tools::PartnerValidationsController do
  render_views

  before :each do
    activate_authlogic
    @user = Factory(:admin)
    @partner = Factory(:partner, :users => [@user])
    login_as(@user)
  end

  describe '#index' do
    it 'renders the validations page' do
      get(:index)
    end

    it 'renders page after sort' do
      get(:index, :acct_mgr_sort => 'DESC')
    end
  end

  describe '#confirm_payouts' do
    before :each do
      @controller.stub(:set_recent_partners)
    end

    context 'when not payout manager' do
      before :each do
        @partner = Factory(:partner, :users => [@user])
        @user = Factory(:payout_manager_user)
        login_as(@user)
        Partner.stub(:find).with(@partner.id).and_return(@partner)
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
        Partner.stub(:find).with(@partner.id).and_return(@partner)
        @controller.stub(:log_activity)
      end

      context 'when partner is confirmed' do
        it 'succeeds' do
          @partner.stub(:confirm_for_payout).and_return(true)
          get(:confirm_payouts, :partner_id => @partner.id)
          response.should be_success
        end

        it 'confirms the partner' do
          @partner.should_receive(:confirm_for_payout).once
          get(:confirm_payouts, :partner_id => @partner.id)
        end
      end
    end
  end
end
