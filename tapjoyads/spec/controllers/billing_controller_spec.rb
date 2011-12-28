require 'spec/spec_helper'

describe BillingController do
  before :each do
    activate_authlogic
    user = Factory(:user)
    @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [user], :transfer_bonus => 0.1)
    login_as(user)
    # remove this line after 12/23
    Time.stubs(:now).returns(Time.parse('2011-12-23'))
  end

  describe "admins creating transfers" do
    it "should log transfer and math should work out" do
      get :create_transfer, { :transfer_amount => '$1.00' }
      @partner.reload

      @partner.orders.length.should == 2
      @partner.payouts.length.should == 1
      @partner.pending_earnings.should == 9_900
      @partner.balance.should == 10_110
    end

    it "should not allow negative transfer" do
      get :create_transfer, { :transfer_amount => '$-1.00' }
      @partner.reload

      @partner.orders.should be_blank
      @partner.payouts.should be_blank
      @partner.pending_earnings.should == 10_000
      @partner.balance.should == 10_000
    end

    it "should not allow transfer greater than pending_earnings amount" do
      get :create_transfer, { :transfer_amount => '$100.01' }
      @partner.reload

      @partner.orders.should be_blank
      @partner.payouts.should be_blank
      @partner.pending_earnings.should == 10_000
      @partner.balance.should == 10_000
    end
  end

  describe 'transfer freeze' do
    describe 'during freeze' do
      before :each do
        @controller.stubs(:during_transfer_freeze?).returns(true)
      end

      it 'should not show transfer page' do
        get :transfer_funds
        @response.should render_template('billing/no_transfer.html.haml')
      end

      it 'should not create transfer' do
        post :create_transfer, { :transfer_amount => '$1.00' }
        flash[:error].should =~ /error/
      end
    end

    describe 'after freeze' do
      before :each do
        @controller.stubs(:during_transfer_freeze?).returns(false)
      end

      it 'should show transfer page' do
        get :transfer_funds
        @response.should render_template('billing/transfer_funds.html.haml')
      end

      it 'should resume creating transfer' do
        post :create_transfer, { :transfer_amount => '$1.00' }
        flash[:error].should be_nil
      end
    end
  end
end
