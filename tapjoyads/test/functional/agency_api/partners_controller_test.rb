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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :name => 'partner', :email => 'email@example.com', :password => 'lkjasdflkj')
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com', :password => 'lkjasdflkj')
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com', :password => 'lkjasdflkj')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        user = User.find_by_email('email@example.com')
        assert_equal user.id, result['user_id']
        assert_equal user.api_key, result['api_key']
        assert_equal 1, user.partners.count
        partner = user.partners.first
        assert_equal partner.id, result['partner_id']
        assert_equal 'partner', partner.name
      end
    end
  end
  
end
