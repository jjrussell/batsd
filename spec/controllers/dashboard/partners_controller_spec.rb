require 'spec_helper'

describe Dashboard::PartnersController do

  before :each do
    activate_authlogic
  end

  context "when creating create transfer" do
    before :each do
      @user = FactoryGirl.create(:admin)
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
      @user = FactoryGirl.create(:agency)
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

  context "when searching" do
    let(:user)    { FactoryGirl.create(:account_manager) }

    before :each do
      login_as(user)
    end

    context 'by email' do
      let(:q) { 'foo@example.com' }
      let(:test_user1) { FactoryGirl.create(:user, :email => q) }
      let(:test_user2) { FactoryGirl.create(:user, :email => 'bar@example.com') }
      let(:partner) { FactoryGirl.create(:partner, :users => [test_user1, test_user2]) }

      it 'responds with partners known to include the user' do
        get :index, :q => q
        assigns(:partners).should include partner
      end

      it 'responds only with partners which include the email' do
        get :index, :q => q
        assigns(:partners).all? {|p| p.users.include(test_user1) }.should be_true
      end

      it 'does not respond with duplicate results' do
        partner.id #lazy load partner
        get :index, :q => 'example.com'
        assigns(:partners).where('partners.id = ?', partner.id).length.should == 1
      end
    end

    context 'by country' do
      let(:country) { 'United States of America' }
      let(:partner) { FactoryGirl.create(:partner, :country => country) }

      before :each do
        get :index, :country => country
      end

      it 'responds with the indicated country' do
        assigns(:country).should == country
      end

      it 'responds with partners known to be from indicated country' do
        assigns(:partners).should include partner
      end

      it 'responds only with partners from the indicated country' do
        assigns(:partners).all? { |p| p.country == country }.should be_true
      end
    end

    context 'by manager' do
      let(:manager) { FactoryGirl.create(:account_manager) }
      let(:partner) { FactoryGirl.create(:partner, :account_managers => [manager]) }

      before :each do
        get :index, :managed_by => manager.id
      end

      it 'responds with partners known to be managed by indicated manager' do
        assigns(:partners).should include partner
      end

      it 'responds only with partners managed by indicated manager' do
        assigns(:partners).all? { |p| p.account_managers.include?(manager) }.should be_true
      end
    end

    context 'by unmanaged' do
      let(:test_user1) { FactoryGirl.create(:user, :email => 'foo@example.com') }
      let(:test_user2) { FactoryGirl.create(:user, :email => 'bar@example.com') }
      let!(:partner) { FactoryGirl.create(:partner, :users => [test_user1, test_user2]) }

      it 'does not respond with duplicate results' do
        get :index, :managed_by => :none
        assigns(:partners).where('partners.id = ?', partner.id).length.should == 1
      end
    end
  end

  context '#update' do
    let(:current_user)  { FactoryGirl.create(:admin) }
    let(:partner)       { FactoryGirl.create(:partner, :users => [current_user]) }

    let(:params)        {{ :id => partner.id, :partner => {:name => "Some new name"} }}

    before(:each) do
      login_as(current_user)
      controller.stub(:current_user).and_return(current_user)
    end

    context 'a user who is a Tapjoy employee' do
      before(:each) { current_user.stub(:employee?).and_return(true) }

      it "can change the partner's name" do
        put(:update, params)
        partner.reload
        partner.name.should == "Some new name"
      end
    end

    context 'a user who is not a Tapjoy employee' do
      before(:each) { current_user.stub(:employee?).and_return(false) }
      it "cannot change the partner's name" do
        put(:update, params)
        partner.reload
        partner.name.should_not == "Some new name"
      end
    end
  end
end
