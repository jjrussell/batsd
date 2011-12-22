require 'spec/spec_helper'

describe CreateAccountController do
  describe "on GET to :index" do
    before :each do
      @agency_user = Factory(:agency_user)
    end

    describe "with missing params" do
      it "should respond with missing required params error" do
        expected_errors = { :error => "missing required parameters" }

        get :index

        @response.should be_success
        @response.content_type.should =~ /json/
        @response.body.should == expected_errors.to_json
      end
    end

    describe 'with an invalid agency_id' do
      it 'should respond with unknown agency_id error' do
        options = {
          :agency_id => 'foo',
          :app_name => 'foo',
          :email => 'foo',
          :password => 'foobaz'
        }
        expected_errors = { :error => "unknown or invalid agency_id" }

        get :index, options

        @response.should be_success
        @response.content_type.should =~ /json/
        @response.body.should == expected_errors.to_json
      end
    end

    describe 'with an invalid email address' do
      it 'should respond with validation errors' do
        options = {
          :agency_id => @agency_user.id,
          :app_name => 'foo',
          :email => 'foo',
          :password => 'foobaz'
        }
        expected_errors = {
          :error => [
            [ :email, 'is too short (minimum is 6 characters)' ],
            [ :email, 'should look like an email address.' ]
          ]
        }

        get :index, options

        @response.should be_success
        @response.content_type.should =~ /json/
        @response.body.should == expected_errors.to_json
      end
    end

    describe 'with an existing email address' do
      it 'should respond with validation errors' do
        options = {
          :agency_id => @agency_user.id,
          :app_name => 'foo',
          :email => @agency_user.email,
          :password => 'foobaz'
        }
        expected_errors = {
          :error => [
            [ :email, 'has already been taken' ],
            [ :username, 'has already been taken' ]
          ]
        }

        get :index, options

        @response.should be_success
        @response.content_type.should =~ /json/
        @response.body.should == expected_errors.to_json
      end
    end

    context "with an invalid password" do
      it 'should respond with validation errors' do
        options = { :agency_id => @agency_user.id,
          :app_name => 'foo',
          :email => Factory.next(:email),
          :password => 'foo'
        }
        expected_errors = {
          :error => [
            [ :password, 'is too short (minimum is 4 characters)' ],
            [ :password_confirmation, 'is too short (minimum is 4 characters)' ]
          ]
        }

        get :index, options

        @response.should be_success
        @response.content_type.should =~ /json/
        @response.body.should == expected_errors.to_json
      end
    end

    context "with valid parameters" do
      it 'should create valid user/partner' do
        email_address = Factory.next(:email)
        app_name = Factory.next(:name)
        options = {
          :agency_id => @agency_user.id,
          :app_name => app_name,
          :email => email_address,
          :password => 'foobaz',
        }

        get :index, options

        app = App.find_by_name(app_name)
        app.should_not be_nil
        user = User.find_by_email(email_address)
        partner = Partner.find_by_name(email_address)
        user.should_not be_nil
        partner.should_not be_nil
        user.partners.map(&:id).should == [ partner.id ]
        @agency_user.partners.map(&:id).should == [ partner.id ]

        @response.should be_success
        @response.content_type.should =~ /json/
        @response.body.should == { :app_id => app.id }.to_json
      end
    end
  end
end
