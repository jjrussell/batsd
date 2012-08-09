require 'spec_helper'

describe Dashboard::PartnersController do
  before :each do
    activate_authlogic
  end

  context "when creating create transfer" do
    before :each do
      @user = FactoryGirl.create(:admin_user)
      @partner = FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      FactoryGirl.create(:app, :partner => @partner)
      FactoryGirl.create(:app, :partner => @partner)
      login_as(@user)
    end

    it "logs transfer and math should work out" do
      amount = rand(100) + 100

      get(:create_transfer, { :transfer => { :amount => amount.to_s, :internal_notes => 'notes', :transfer_type => '5' }, :id => @partner.id })
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

      get(:create_transfer, { :transfer => { :amount => amount.to_s, :internal_notes => 'notes', :transfer_type => '5' }, :id => @partner.id })
      @partner.reload

      @partner.orders.length.should == 2
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 10000 - amount*100
      @partner.balance.should == 10000 + amount*100 + bonus*100
    end

    it "ignore bonus if a recoupable marketing credit" do
      @partner.transfer_bonus = 0.1
      @partner.save
      amount = rand(100) + 100
      bonus = (amount * @partner.transfer_bonus)

      get(:create_transfer, { :transfer => { :amount => amount.to_s, :internal_notes => 'notes', :transfer_type => '4' }, :id => @partner.id})
      @partner.reload

      assert_equal 1, @partner.orders.length
      assert_equal 1, @partner.payouts.length
      assert_equal 10000 - amount*100, @partner.pending_earnings
      assert_equal 10000 + amount*100, @partner.balance
    end
  end

  context "when agencies act as partners" do
    before :each do
      @user = FactoryGirl.create(:agency_user)
      @partner1 = @partner = FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])
      @partner2 = @partner = FactoryGirl.create(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user])

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
