require 'spec_helper'

describe Dashboard::Tools::GenericOffersController do
  render_views

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
      @user = FactoryGirl.create(:agency)
      @partner = FactoryGirl.create(:partner, :users => [@user])
      login_as(@user)
    end

    context "accessing generic offers index" do
      it "redirects to dashboard" do
        get(:index)
        response.should redirect_to(root_path)
      end
    end
  end

  context "with an admin user" do
    before :each do
      @user = FactoryGirl.create(:admin)
      @partner = FactoryGirl.create(:partner, :users => [@user])
      @generic_offer = FactoryGirl.create(:generic_offer, :partner => @partner)
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
        response.body.should have_selector('table#generic_offers_table') do |element|
          element.should have_content(@generic_offer.name)
        end
      end
    end

    # Test that we can update a generic offer's category
    it "updates generic offer category" do
      post(:update, :id => @generic_offer.id, :generic_offer => { :category => GenericOffer::CATEGORIES.first })
      @generic_offer.reload
      GenericOffer::CATEGORIES.first.should == @generic_offer.category
    end

    describe 'create' do
      before(:each) do
        @params = {:generic_offer => { :category => GenericOffer::CATEGORIES.first, :partner_id => @partner.id, :name => 'SomeOffer', :url => 'http://www.example.com' }}
      end

      it "can create generic offers" do
        lambda{ post(:create, @params) }.should change(GenericOffer, :count).by(1)
      end

      it "can set primary_offer_attributes on creation" do
        @params[:generic_offer].merge!(:primary_offer_attributes => {:featured_ad_content => 'Featured Ad Content'})
        post(:create, @params)

        assigns[:generic_offer].primary_offer.featured_ad_content.should == 'Featured Ad Content'
      end

    end
  end
end
