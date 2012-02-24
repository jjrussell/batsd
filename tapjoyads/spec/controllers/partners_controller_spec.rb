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

      get(:create_transfer, { :transfer_amount => amount, :id => @partner.id })
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

      get(:create_transfer, { :transfer_amount => amount, :id => @partner.id })
      @partner.reload

      @partner.orders.length.should == 2
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 10000 - amount*100
      @partner.balance.should == 10000 + amount*100 + bonus*100
    end

  end

  describe '#set_unconfirmed_for_payout' do
    before :each do
      @user = Factory(:admin)
      @partner = Factory(:partner, :users => [@user])
      @partner.confirmed_for_payout = true
      @partner.save
      login_as(@user)
      post(:set_unconfirmed_for_payout, :id => @partner.id, :payout_notes => "Test")
      @partner.reload
    end

    context "when partner is not confirmed" do
      it "redirects to partner page" do
        response.should redirect_to(partner_path)
      end

      it "will unconfirm the partner" do
        @partner.confirmed_for_payout.should be_false
      end

      it "will add the given reason" do
        @partner.payout_confirmation_notes.should == "Test"
      end
    end
  end

  context "when agencies act as partners" do
    before :each do
      @user = Factory(:agency_user)
      @partner1 = @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      @partner2 = @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])

      post(:make_current, {:id => @partner2.id})
    end

    it "clears the last_shown_app session" do
      session[:last_shown_app].should be_nil
    end

    it "changes the current_partner" do
      @controller.send(:current_partner).should == @partner2
    end
  end
end
