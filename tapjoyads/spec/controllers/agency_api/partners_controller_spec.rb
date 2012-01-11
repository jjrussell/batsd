require 'spec/spec_helper'

describe AgencyApi::PartnersController do

  describe "on GET to :index" do
    before :each do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner, :balance => 10, :pending_earnings => 11, :name => 'name', :contact_name => 'contact_name')
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
    end

    describe "with missing params" do
      it "should respond with error" do
        get :index
        should_respond_with_json_error(400)
      end
    end

    describe "with bad credentials" do
      it "should respond with error" do
        get :index, :agency_id => @agency_user.id, :api_key => 'foo'
        should_respond_with_json_error(403)
      end
    end

    describe "with valid params" do
      it "should respond with success" do
        get :index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        expected_response = {
          'partner_id'       => @partner.id,
          'name'             => @partner.name,
          'balance'          => @partner.balance,
          'pending_earnings' => @partner.pending_earnings,
          'contact_email'    => @partner.contact_name,
        }
        result['partners'].should == [expected_response]
      end
    end
  end

  describe "on GET to :show" do
    before :each do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner, :balance => 10, :pending_earnings => 11, :name => 'name', :contact_name => 'contact_name')
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @partner2 = Factory(:partner)
    end

    describe "with missing params" do
      it "should respond with error" do
        get :index, :id => 'not_a_partner_id'
        should_respond_with_json_error(400)
      end
    end

    describe "with bad credentials" do
      it "should respond with error" do
        get :index, :id => @partner.id, :agency_id => @agency_user.id, :api_key => 'foo'
        should_respond_with_json_error(403)
      end
    end

    describe "with an invalid partner_id" do
      it "should respond with error" do
        get :show, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key
        should_respond_with_json_error(403)
      end
    end

    describe "with a partner_id not belonging to the agency" do
      it "should respond with error" do
        @currency2 = Factory(:currency)
        get :show, :id => @partner2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key
        should_respond_with_json_error(403)
      end
    end

    describe "with valid params" do
      it "should respond with success" do
        get :show, :id => @partner.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        result['partner_id'].should == @partner.id
        result['name'].should == @partner.name
        result['balance'].should == @partner.balance
        result['pending_earnings'].should == @partner.pending_earnings
        result['contact_email'].should == @partner.contact_name
      end
    end
  end

  describe "on POST to :create" do
    before :each do
      @reseller = Factory(:reseller)
      @agency_user = Factory(:agency_user, :reseller => @reseller)
    end

    describe "with missing params" do
      it "should respond with error" do
        post :create
        should_respond_with_json_error(400)
      end
    end

    describe "with bad credentials" do
      it "should respond with error" do
        post :create, :agency_id => @agency_user.id, :api_key => 'foo', :name => 'partner', :email => 'email@example.com'
        should_respond_with_json_error(403)
      end
    end

    describe "with invalid params" do
      it "should respond with error" do
        Factory(:user, :email => 'email@example.com')
        post :create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com'
        should_respond_with_json_error(400)
      end
    end

    describe "with valid params" do
      it "should respond with success" do
        post :create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com'
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        user = User.find_by_email('email@example.com')
        user.partners.count.should == 1
        partner = user.partners.first
        result['partner_id'].should == partner.id
        partner.name.should == 'partner'
        partner.reseller_id.should == @reseller.id
      end
    end
  end

  describe "on POST to :link" do
    before :each do
      @agency_user = Factory(:agency_user)
      @user = Factory(:user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @user, :partner => @partner)
    end

    describe "with missing params" do
      it "should respond with error" do
        post :link
        should_respond_with_json_error(400)
      end
    end

    describe "with bad credentials" do
      it "should respond with error" do
        post :link, :agency_id => @agency_user.id, :api_key => 'foo', :email => @user.email, :user_api_key => @user.api_key
        should_respond_with_json_error(403)
      end
    end

    describe "with bad user credentials" do
      it "should respond with error" do
        post :link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => 'foo'
        should_respond_with_json_error(403)
      end
    end

    describe "with an invalid email" do
      it "should respond with error" do
        post :link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => 'email@example.com', :user_api_key => @user.api_key
        should_respond_with_json_error(400)
      end
    end

    describe "for a user with too many partner accounts" do
      it "should respond with error" do
        @partner2 = Factory(:partner)
        PartnerAssignment.create!(:user => @user, :partner => @partner2)
        post :link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key
        should_respond_with_json_error(400)
      end
    end

    describe "with valid params" do
      it "should respond with success" do
        post :link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key
        should_respond_with_json_success(200)
        result = JSON.parse(response.body)
        result['partner_id'].should == @partner.id
      end
    end
  end

  describe "on PUT to :update" do
    before :each do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      @partner2 = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
    end

    describe "with missing params" do
      it "should respond with error" do
        put :update, :id => 'not_a_partner_id'
        should_respond_with_json_error(400)
      end
    end

    describe "with bad credentials" do
      it "should respond with error" do
        put :update, :id => @partner.id, :agency_id => @agency_user.id, :api_key => 'foo'
        should_respond_with_json_error(403)
      end
    end

    describe "with an invalid id" do
      it "should respond with error" do
        put :update, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key
        should_respond_with_json_error(403)
      end
    end

    describe "with an id belonging to an invalid partner" do
      it "should respond with error" do
        @currency2 = Factory(:currency)
        put :update, :id => @partner2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key
        should_respond_with_json_error(403)
      end
    end

    describe "with valid params" do
      it "should respond with success" do
        put :update, :id => @partner.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner_rename'
        should_respond_with_json_success(200)
        @partner.reload
        @partner.name.should == 'partner_rename'
      end
    end
  end
end
