require 'test_helper'

class CreateAccountControllerTest < ActionController::TestCase

  context "on GET to :index" do
    setup do
      @agency_user = Factory(:agency_user)
    end

    context "with missing params" do
      setup do
        @response = get(:index)
      end
      should respond_with(:success)
      should respond_with_content_type(:json)
      should "respond with missing required params error" do
        assert_equal({ :error => "missing required parameters" }.to_json, @response.body)
      end
    end

    context "with an invalid agency_id" do
      setup do
        @response = get(:index, { :agency_id => 'foo', :app_name => 'foo', :email => 'foo', :password => 'foobaz' })
      end
      should respond_with(:success)
      should respond_with_content_type(:json)
      should "respond with unknown agency_id error" do
        assert_equal({ :error => "unknown or invalid agency_id" }.to_json, @response.body)
      end
    end

    context "with an invalid email address" do
      setup do
        @response = get(:index, { :agency_id => @agency_user.id, :app_name => 'foo', :email => 'foo', :password => 'foobaz' })
      end
      should respond_with(:success)
      should respond_with_content_type(:json)
      should "respond with validation errors" do
        assert_equal({ :error => [ [ :email, 'is too short (minimum is 6 characters)' ], [ :email, 'should look like an email address.' ] ] }.to_json, @response.body)
      end
    end

    context "with an existing email address" do
      setup do
        @response = get(:index, { :agency_id => @agency_user.id, :app_name => 'foo', :email => @agency_user.email, :password => 'foobaz' })
      end
      should respond_with(:success)
      should respond_with_content_type(:json)
      should "respond with validation errors" do
        assert_equal({ :error => [ [ :email, 'has already been taken' ], [ :username, 'has already been taken' ] ] }.to_json, @response.body)
      end
    end

    context "with an invalid password" do
      setup do
        @response = get(:index, { :agency_id => @agency_user.id, :app_name => 'foo', :email => Factory.next(:email), :password => 'foo' })
      end
      should respond_with(:success)
      should respond_with_content_type(:json)
      should "respond with validation errors" do
        assert_equal({ :error => [ [ :password, 'is too short (minimum is 4 characters)' ], [ :password_confirmation, 'is too short (minimum is 4 characters)' ] ] }.to_json, @response.body)
      end
    end

    context "with valid parameters" do
      setup do
        @email_address = Factory.next(:email)
        @app_name = Factory.next(:name)
        @response = get(:index, { :agency_id => @agency_user.id, :app_name => @app_name, :email => @email_address, :password => 'foobaz' })
        @user = User.find_by_email(@email_address)
        @partner = Partner.find_by_name(@email_address)
        @app = App.find_by_name(@app_name)
      end
      should respond_with(:success)
      should respond_with_content_type(:json)
      should "create a user" do
        assert_not_nil @user
      end
      should "create a partner" do
        assert_not_nil @partner
      end
      should "create two partner_assignments" do
        assert_not_nil PartnerAssignment.find_by_user_id_and_partner_id(@user.id, @partner.id)
        assert_not_nil PartnerAssignment.find_by_user_id_and_partner_id(@agency_user.id, @partner.id)
      end
      should "create an app" do
        assert_not_nil @app
      end
      should "respond with the new app_id" do
        assert_equal({ :app_id => @app.id }.to_json, @response.body)
      end
    end
  end

end
