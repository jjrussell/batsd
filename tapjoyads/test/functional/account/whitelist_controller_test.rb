require 'test_helper'

class Account::WhitelistControllerTest < ActionController::TestCase
  setup :activate_authlogic
  context 'on GET to :index' do
    setup do
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

    should "assign all offers by default" do
      get :index
      assert_equal [@offer1, @offer2], assigns(:offers)
    end

    should "assign approved offers" do
      get :index, :status => 'a'
      assert_equal [@offer1], assigns(:offers)
    end

    should "assign blocked offers" do
      get :index, :status => 'b'
      assert_equal [@offer2], assigns(:offers)
    end

    should "assign offers by device" do
      get :index, :device => 'all'
      assert_equal [@offer1, @offer2], assigns(:offers)

      get :index, :device => 'iphone'
      assert_equal [@offer1, @offer2], assigns(:offers)

      get :index, :device => 'android'
      assert_equal [], assigns(:offers)

      @offer1.device_types = ['android'].to_json
      @offer1.save
      get :index, :device => 'android'
      assert_equal [@offer1], assigns(:offers)
    end

    should "assign offers by name" do
      @offer1.name = 'bill'
      @offer1.save!
      @offer2.name = 'sue'
      @offer2.save!

      get :index, :name => 'bill'
      assert_equal [@offer1], assigns(:offers)
      get :index, :name => 'sue'
      assert_equal [@offer2], assigns(:offers)
      get :index, :name => 'sarah'
      assert_equal [], assigns(:offers)
      get :index
      assert_equal [@offer1, @offer2], assigns(:offers)
    end
  end

  context 'on GET to :enable' do
    setup do
      @user = Factory(:admin)
      @offer = Factory(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.user_enabled = true
      @offer.save
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user], :offers => [@offer], :use_whitelist => true)
      login_as @user
    end

    should "redirect to account whitelist index" do
      get :enable
      assert_redirected_to(account_whitelist_index_path)
    end

    should "add offer to whitelist" do
      get :index, :status => 'a'
      assert_equal [], assigns(:offers)
      get :enable, :id => @offer.id
      get :index, :status => 'a'
      assert_equal [@offer], assigns(:offers)
      @partner.reload
      assert_equal Set.new(@offer.id), @partner.get_offer_whitelist
    end

    should "log activity" do
      get :enable, :id => @offer.id
      assert assigns(:activity_logs)
    end
  end

  context 'on GET to :disable' do
    setup do
      @user = Factory(:admin)
      @offer = Factory(:app).primary_offer
      @offer.tapjoy_enabled = true
      @offer.user_enabled = true
      @offer.save
      @partner = Factory(:partner, :pending_earnings => 10000, :balance => 10000, :users => [@user], :offers => [@offer], :use_whitelist => true)
      login_as @user
    end

    should "redirect to account whitelist index" do
      get :disable
      assert_redirected_to(account_whitelist_index_path)
    end

    should "remove offer from whitelist" do
      get :enable, :id => @offer.id
      get :index, :status => 'b'
      assert_equal [], assigns(:offers)
      get :disable, :id => @offer.id
      get :index, :status => 'b'
      assert_equal [@offer], assigns(:offers)
      @partner.reload
      assert_equal Set.new, @partner.get_offer_whitelist
    end

    should "log activity" do
      get :disable, :id => @offer.id
      assert assigns(:activity_logs)
    end
  end
end
