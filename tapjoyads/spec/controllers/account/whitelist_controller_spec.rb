require 'spec_helper'

describe Account::WhitelistController do
  before :each do
    activate_authlogic
    fake_the_web
  end

  context 'on GET to :index' do
    before :each do
      @user = Factory(:admin)
      @offer1 = Factory(:app).primary_offer
      @offer2 = Factory(:app).primary_offer
      @offer1.tapjoy_enabled = true
      @offer1.user_enabled = true
      @offer1.save
      @offer2.tapjoy_enabled = true
      @offer2.user_enabled = true
      @offer2.save
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user], :offers => [@offer1, @offer2], :use_whitelist => true)
      @partner.add_to_whitelist(@offer1.id)
      @partner.save
      login_as @user
    end

    it "should assign all offers by default" do
      get :index
      assigns(:offers).should == [@offer1, @offer2]
    end

    it "should assign approved offers" do
      get :index, :status => 'a'
      assigns(:offers).should == [@offer1]
    end

    it "should assign blocked offers" do
      get :index, :status => 'b'
      assigns(:offers).should == [@offer2]
    end

    it "should assign offers by device" do
      get :index, :device => 'all'
      assigns(:offers).should == [@offer1, @offer2]

      get :index, :device => 'iphone'
      assigns(:offers).should == [@offer1, @offer2]

      get :index, :device => 'android'
      assigns(:offers).should == []

      @offer1.device_types = ['android'].to_json
      @offer1.save
      get :index, :device => 'android'
      assigns(:offers).should == [@offer1]
    end

    it "should assign offers by name" do
      @offer1.name = 'bill'
      @offer1.save!
      @offer2.name = 'sue'
      @offer2.save!

      get :index, :name => 'bill'
      assigns(:offers).should == [@offer1]
      get :index, :name => 'sue'
      assigns(:offers).should == [@offer2]
      get :index, :name => 'sarah'
      assigns(:offers).should == []
      get :index
      assigns(:offers).should == [@offer1, @offer2]
    end
  end

  context 'on GET to :enable' do
    before :each do
      @user = Factory(:admin)
      @offer = Factory(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.user_enabled = true
      @offer.save
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user], :offers => [@offer], :use_whitelist => true)
      login_as @user
    end

    it "should redirect to account whitelist index" do
      get :enable
      response.should redirect_to(account_whitelist_index_path)
    end

    it "should add offer to whitelist" do
      get :index, :status => 'a'
      assigns(:offers).should == []
      get :enable, :id => @offer.id
      get :index, :status => 'a'
      assigns(:offers).should == [@offer]
      @partner.reload
      @partner.get_offer_whitelist.should == Set.new(@offer.id)
    end

    it "should log activity" do
      get :enable, :id => @offer.id
      assigns(:activity_logs).should_not be_nil
    end
  end

  context 'on GET to :disable' do
    before :each do
      @user = Factory(:admin)
      @offer = Factory(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.user_enabled = true
      @offer.save
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user], :offers => [@offer], :use_whitelist => true)
      login_as @user
    end

    it "should redirect to account whitelist index" do
      get :disable
      response.should redirect_to(account_whitelist_index_path)
    end

    it "should remove offer from whitelist" do
      get :enable, :id => @offer.id
      get :index, :status => 'b'
      assigns(:offers).should == []
      get :disable, :id => @offer.id
      get :index, :status => 'b'
      assigns(:offers).should == [@offer]
      @partner.reload
      @partner.get_offer_whitelist.should == Set.new
    end

    it "should log activity" do
      get :disable, :id => @offer.id
      assigns(:activity_logs).should_not be_nil
    end
  end
end
