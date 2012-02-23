require 'spec_helper'

describe Tools::GenericOffersController do
  integrate_views

  before :each do
    activate_authlogic
  end

  context "with a non-logged in user" do
    it "redirects to login page" do
      get(:index)
      response.should redirect_to(login_path(:goto => tools_generic_offers_path))
    end
  end

  context "with an unauthorized user" do
    before :each do
      @user = Factory(:agency_user)
      @partner = Factory(:partner, :users => [@user])
      login_as(@user)
    end

    context "accessing generic offers index" do
      it "redirects to dashboard" do
        get(:index)
        response.should redirect_to(dashboard_root_path)
      end
    end
  end

  context "with an admin user" do
    before :each do
      @user = Factory(:admin)
      @partner = Factory(:partner, :users => [@user])
      @generic_offer = Factory(:generic_offer, :partner => @partner)
      login_as(@user)
    end

    context "accessing generic offers index" do
      it "renders appropriate page" do
        get(:index)
        response.should render_template "tools/generic_offers/index"
      end

      it "displays generic offers" do
        get(:index)
        assigns(:generic_offers).should include @generic_offer
        response.should have_tag('table#generic_offers_table') do |element|
          element.should have_tag('td', @generic_offer.name)
        end
      end
    end

    # Test that we can update a generic offer's category
    it "updates generic offer category" do
      post(:update, :id => @generic_offer.id, :generic_offer => { :category => GenericOffer::CATEGORIES.first })
      @generic_offer.reload
      GenericOffer::CATEGORIES.first.should == @generic_offer.category
    end
  end
end
