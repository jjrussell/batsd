require 'spec/spec_helper'

describe Tools::PayoutsController do
  integrate_views

  before :each do
    activate_authlogic
  end

  before :each do
    @user = Factory :admin
    @partner = Factory(:partner, :users => [@user])
    login_as @user
  end

  it 'renders payouts page' do
    get :index
  end

  describe 'confirmed for payout' do
    it 'does not allow payops to modify' do
      post :confirm_payouts, { :id => @partner.id }
      response.should_not be_success
    end

    it 'does allow payout manager to modify' do
      @user = Factory :payout_manager_user
      login_as @user

      post :confirm_payouts, { :partner_id => @partner.id }
      response.should be_success
    end

    it 'unconfirms partner when partner is confirmed' do
      @user = Factory :payout_manager_user
      login_as @user

      @partner.confirmed_for_payout = true
      @partner.save
      post :confirm_payouts, { :partner_id => @partner.id }
      @partner.reload
      @partner.confirmed_for_payout.should_not be_true
    end

    it 'confirms partner when partner is not confirmed' do
      @user = Factory :payout_manager_user
      login_as @user

      @partner.confirmed_for_payout = false
      @partner.save
      post :confirm_payouts, { :partner_id => @partner.id }
      @partner.reload
      @partner.confirmed_for_payout.should be_true
    end

  end
end
