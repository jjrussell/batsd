require 'spec_helper'

describe Dashboard::Tools::PartnerValidationsController do
  render_views

  before :each do
    activate_authlogic
    @user = FactoryGirl.create(:admin)
    @partner = FactoryGirl.create(:partner, :users => [@user])
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
      Partner.stub(:find).with(@partner.id).and_return(@partner)
      @controller.stub(:log_activity)
      @controller.stub(:set_recent_partners)
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
