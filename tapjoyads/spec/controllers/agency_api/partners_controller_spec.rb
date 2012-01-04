require 'spec/spec_helper'

describe AgencyApi::PartnersController do

  describe "on GET to :index" do
    before :each do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner, :balance => 10, :pending_earnings => 11, :name => 'name', :contact_name => 'contact_name')
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
    end

    describe "with missing params" do
      before :each do
        @response = get(:index)
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with bad credentials" do
      before :each do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with valid params" do
      before :each do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      it "should respond with success" do
        should respond_with(200)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_true
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
      before :each do
        @response = get(:index, :id => 'not_a_partner_id')
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with bad credentials" do
      before :each do
        @response = get(:index, :id => @partner.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with an invalid partner_id" do
      before :each do
        @response = get(:show, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with a partner_id not belonging to the agency" do
      before :each do
        @currency2 = Factory(:currency)
        @response = get(:show, :id => @partner2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with valid params" do
      before :each do
        @response = get(:show, :id => @partner.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      it "should respond with success" do
        should respond_with(200)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_true
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
      before :each do
        @response = post(:create)
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with bad credentials" do
      before :each do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :name => 'partner', :email => 'email@example.com')
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with invalid params" do
      before :each do
        Factory(:user, :email => 'email@example.com')
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com')
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with valid params" do
      before :each do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com')
      end
      it "should respond with success" do
        should respond_with(200)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_true
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
      before :each do
        @response = post(:link)
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with bad credentials" do
      before :each do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => 'foo', :email => @user.email, :user_api_key => @user.api_key)
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with bad user credentials" do
      before :each do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => 'foo')
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with an invalid email" do
      before :each do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => 'email@example.com', :user_api_key => @user.api_key)
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "for a user with too many partner accounts" do
      before :each do
        @partner2 = Factory(:partner)
        PartnerAssignment.create!(:user => @user, :partner => @partner2)
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key)
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with valid params" do
      before :each do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key)
      end
      it "should respond with success" do
        should respond_with(200)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_true
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
      before :each do
        @response = put(:update, :id => 'not_a_partner_id')
      end
      it "should respond with error" do
        should respond_with(400)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with bad credentials" do
      before :each do
        @response = put(:update, :id => @partner.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with an invalid id" do
      before :each do
        @response = put(:update, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with an id belonging to an invalid partner" do
      before :each do
        @currency2 = Factory(:currency)
        @response = put(:update, :id => @partner2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      it "should respond with error" do
        should respond_with(403)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        result['success'].should be_false
        result['error'].should be_present
      end
    end
    describe "with valid params" do
      before :each do
        @response = put(:update, :id => @partner.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner_rename')
      end
      it "should respond with success" do
        should respond_with(200)
        should respond_with_content_type(:json)
        result = JSON.parse(@response.body)
        @partner.reload
        result['success'].should be_true
        @partner.name.should == 'partner_rename'
      end
    end
  end
end
