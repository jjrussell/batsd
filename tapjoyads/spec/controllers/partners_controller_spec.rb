require 'spec_helper'

describe PartnersController do
  before :each do
    activate_authlogic
  end

  context "when creating create transfer" do
    before :each do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      login_as(@user)
    end

    it "logs transfer and math should work out" do
      amount = rand(100) + 100

      get :create_transfer, { :transfer_amount => amount, :id => @partner.id }
      @partner.reload

      response.should be_redirect
      @partner.orders.length.should == 1
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 10000 - amount*100
      @partner.balance.should == 10000 + amount*100
    end

    it "creates bonus if necessary" do
      @partner.transfer_bonus = 0.1
      @partner.save
      amount = rand(100) + 100
      bonus = (amount * @partner.transfer_bonus)

      get :create_transfer, { :transfer_amount => amount, :id => @partner.id }
      @partner.reload

      @partner.orders.length.should == 2
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 10000 - amount*100
      @partner.balance.should == 10000 + amount*100 + bonus*100
    end

  end

  context "when manually unconfirming a partner" do
    before :each do
      @user = Factory(:admin)
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      Factory(:app, :partner => @partner)
      Factory(:app, :partner => @partner)
      @partner.confirmed_for_payout = true
      @partner.save
      login_as(@user)
    end

    it "should unconfirm the partner" do
      @partner.confirmed_for_payout.should be_true
      post :set_unconfirmed_for_payout, {:id => @partner.id}
      @partner.reload

      response.should be_redirect
      @partner.confirmed_for_payout.should_not be_true
    end

    it "should add a reason if given" do
      payout_confirmation_notes = params[:payout_notes]
      @partner.payout_confirmation_notes.should be_nil
      post :set_unconfirmed_for_payout, {:id => @partner.id, :payout_notes => "Test" }
      @partner.reload

      response.should be_redirect
      @partner.payout_confirmation_notes.should == "Test"
    end
  end
end
