require 'test_helper'

class AgencyApi::AppsControllerTest < ActionController::TestCase
  
  context "on GET to :index" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      @partner2 = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @app = Factory(:app, :partner => @partner)
    end
    
    context "with missing params" do
      setup do
        @response = get(:index)
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
        @response = get(:index, :agency_id => @agency_user.id, :api_key => 'foo', :partner_id => @partner.id)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid partner_id" do
      setup do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner2.id)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner.id)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal [{ 'app_id' => @app.id, 'name' => @app.name, 'platform' => @app.platform, 'store_id' => @app.store_id }], result['apps']
      end
    end
  end
  
  context "on POST to :create" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      @partner2 = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :partner_id => @partner.id, :name => 'app', :platform => 'iphone')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid partner_id" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner2.id, :name => 'app', :platform => 'iphone')
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner.id, :name => 'app', :platform => 'foo')
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
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :partner_id => @partner.id, :name => 'app', :platform => 'iphone')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal 1, @partner.apps.count
        app = @partner.apps.first
        assert_equal app.id, result['app_id']
      end
    end
  end
  
end
