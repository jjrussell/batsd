require 'test_helper'

class Tools::GenericOffersControllerTest < ActionController::TestCase
  setup :activate_authlogic

  context "with a non-logged in user" do
    should "redirect to login page" do
      get :index
      assert_redirected_to(login_path(:goto => tools_generic_offers_path))
    end
  end

  context "with an unauthorized user" do
    setup do
      @user = Factory(:agency_user)
      @partner = Factory(:partner, :users => [@user])
      login_as(@user)
    end

    context "accessing generic offers index" do
      should "redirect to dashboard" do
        get :index
        assert_redirected_to(dashboard_root_path)
      end
    end
  end

  context "with an admin user" do
    setup do
      @user = Factory(:admin)
      @partner = Factory(:partner, :users => [@user])
      @generic_offer = Factory(:generic_offer, :partner => @partner)
      login_as(@user)
    end

    context "accessing generic offers index" do
      should "render appropriate page" do
        get :index
        assert_template "generic_offers/index"
      end

      should "display generic offers" do
        get :index
        assert assigns(:generic_offers).include? @generic_offer
        assert_select 'table#generic_offers_table' do
          assert_select 'td', @generic_offer.name
        end
      end
    end

    # Test that we can update a generic offer's category
    should "update generic offer category" do
      post :update, :id => @generic_offer.id, :generic_offer => { :category => GenericOffer::CATEGORIES.first }
      @generic_offer.reload
      assert_equal @generic_offer.category, GenericOffer::CATEGORIES.first
    end
  end
end
