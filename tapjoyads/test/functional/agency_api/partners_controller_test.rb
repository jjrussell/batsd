require 'test_helper'

class AgencyApi::PartnersControllerTest < ActionController::TestCase
  
  context "on POST to :create" do
    setup do
      @agency_user = Factory(:agency_user)
    end
    
    context "with missing params" do
      setup do
        @response = post(:create)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :name => 'partner', :email => 'email@example.com')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with invalid params" do
      setup do
        Factory(:user, :email => 'email@example.com')
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        user = User.find_by_email('email@example.com')
        assert_equal 1, user.partners.count
        partner = user.partners.first
        assert_equal partner.id, result['partner_id']
        assert_equal 'partner', partner.name
      end
    end
  end
  
  context "on POST to :link" do
    setup do
      @agency_user = Factory(:agency_user)
      @user = Factory(:user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @user, :partner => @partner)
    end
    
    context "with missing params" do
      setup do
        @response = post(:link)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => 'foo', :email => @user.email, :user_api_key => @user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad user credentials" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid email" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => 'email@example.com', :user_api_key => @user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "for a user with too many partner accounts" do
      setup do
        @partner2 = Factory(:partner)
        PartnerAssignment.create!(:user => @user, :partner => @partner2)
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal @partner.id, result['partner_id']
      end
    end
  end
  
end
